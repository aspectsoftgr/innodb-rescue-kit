# Copyright (c) contributors
# Licensed under the MIT License.
# Adapt paths, credentials, and folder names before running.

param(
  [string]$MysqlExe = "C:\xampp\mysql\bin\mysql.exe",
  [string]$MysqlDumpExe = "C:\xampp\mysql\bin\mysqldump.exe",
  [string]$PythonExe = "C:\Python3\python.exe",
  [string]$DbsakeRunner = "C:\tools\dbsake_blobfix_runner.py",
  [string]$MysqlUser = "root",
  [string]$MysqlPassword = "root",
  [string]$BrokenList = "C:\broken_tables_exact.txt",
  [string]$OldDataDir = "C:\xampp\mysql\data_orphaned_for_recovery",
  [string]$ActiveDataDir = "C:\xampp\mysql\data",
  [string]$WorkDir = "C:\ibd_recovery_work",
  [string]$DumpDir = "C:\ibd_recovery_dumps",
  [string]$Log = "C:\ibd_recovery_log.csv",
  [bool]$DumpAlreadyOk = $true
)

$ErrorActionPreference = "Continue"

function Get-AuthArgs {
  $authArgs = @("-u", $MysqlUser)
  if ($MysqlPassword -ne "") {
    $authArgs += "-p$MysqlPassword"
  }
  return $authArgs
}

function Get-CmdAuthFragment {
  if ($MysqlPassword -ne "") {
    return "-u `"$MysqlUser`" -p`"$MysqlPassword`""
  }
  return "-u `"$MysqlUser`""
}

function Get-SqlName([string]$Db, [string]$Table) {
  return "``$Db``.``$Table``"
}

function Add-RecoveryLog([string]$TableName, [string]$Status, [string]$Rows, [string]$Message) {
  [PSCustomObject]@{
    Table = $TableName
    Status = $Status
    Rows = $Rows
    Message = $Message
  } | Export-Csv -Path $Log -Append -NoTypeInformation -Encoding ASCII
}

function Get-RowCount([string]$Db, [string]$Table) {
  $auth = Get-AuthArgs
  $q = Get-SqlName $Db $Table
  $out = & $MysqlExe @auth -N -e "SELECT COUNT(*) FROM $q;" 2>&1
  if ($LASTEXITCODE -eq 0) {
    return (($out | Select-Object -First 1) -as [string]).Trim()
  }
  return ""
}

function Test-TableOk([string]$Db, [string]$Table) {
  $auth = Get-AuthArgs
  $q = Get-SqlName $Db $Table
  $out = & $MysqlExe @auth -N -e "CHECK TABLE $q;" 2>&1
  return ($LASTEXITCODE -eq 0 -and (($out | Out-String) -match "\sOK\s*$"))
}

function Dump-RecoveredTable([string]$Db, [string]$Table, [string]$DumpFile) {
  $auth = Get-AuthArgs
  & $MysqlDumpExe @auth $Db $Table --single-transaction --quick "--result-file=$DumpFile" 2>&1
  return $LASTEXITCODE
}

function Patch-VarcharDefaultLengths([string]$Sql) {
  $pattern = '(?im)^(\s*`\w+`\s+varchar\((\d+)\)[^,]*?\s+DEFAULT\s+'')([^'']*)(''.*)$'
  return [regex]::Replace($Sql, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{
    param($m)
    $max = [int]$m.Groups[2].Value
    $value = $m.Groups[3].Value
    if ($value.Length -gt $max) {
      # Keep the opening and closing quote, making DEFAULT ''.
      return $m.Groups[1].Value + $m.Groups[4].Value
    }
    return $m.Value
  })
}

function Patch-SchemaForImport([string]$Raw) {
  $patched = $Raw

  # Remove secondary indexes; keep PRIMARY KEY because InnoDB stores rows in the clustered primary key when present.
  $patched = $patched -replace '(?m)^\s*(UNIQUE\s+KEY|FULLTEXT\s+KEY|SPATIAL\s+KEY|KEY)\s+.*\r?\n',''

  # Remove simple one-line foreign keys/constraints. Complex multi-line constraints may need manual cleanup.
  $patched = $patched -replace '(?m)^\s*(CONSTRAINT|FOREIGN\s+KEY)\s+.*\r?\n',''

  # MariaDB can reject old nullable timestamp/datetime defaults unless NULL is explicit.
  $patched = $patched -replace '(?im)(`\w+`\s+timestamp(?:\(\d+\))?\s+)(DEFAULT\s+NULL)', '$1NULL $2'
  $patched = $patched -replace '(?im)(`\w+`\s+datetime(?:\(\d+\))?\s+)(DEFAULT\s+NULL)', '$1NULL $2'

  # dbsake/encoding issues can emit a default longer than varchar(n). Make it DEFAULT ''.
  $patched = Patch-VarcharDefaultLengths $patched

  # Remove dangling comma before ") ENGINE".
  $patched = $patched -replace ',\s*(\r?\n\s*\)\s*ENGINE)', '$1'

  return $patched
}

foreach ($required in @($MysqlExe, $MysqlDumpExe, $PythonExe, $DbsakeRunner, $BrokenList, $OldDataDir, $ActiveDataDir)) {
  if (!(Test-Path $required)) {
    throw "Required path not found: $required"
  }
}

New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null
New-Item -ItemType Directory -Force -Path $DumpDir | Out-Null
"Table,Status,Rows,Message" | Set-Content -Path $Log -Encoding ASCII

$tables = Get-Content $BrokenList |
  ForEach-Object { $_.Trim() } |
  Where-Object { $_ -ne "" -and $_ -match "^[^.]+\.[^.]+$" } |
  Sort-Object -Unique

$total = $tables.Count
$index = 0
$auth = Get-AuthArgs

Write-Host "Starting orphaned .ibd recovery"
Write-Host "Tables in queue: $total"
Write-Host "Log: $Log"
Write-Host "Dumps: $DumpDir"

foreach ($entry in $tables) {
  $index++
  $db, $table = $entry.Split(".", 2)
  $q = Get-SqlName $db $table
  Write-Host "[$index/$total] $entry"

  $frm = Join-Path $OldDataDir "$db\$table.frm"
  $ibd = Join-Path $OldDataDir "$db\$table.ibd"

  if (!(Test-Path $frm) -or !(Test-Path $ibd)) {
    Add-RecoveryLog $entry "SKIP" "" "Missing .frm or .ibd"
    continue
  }

  $safe = ($entry -replace '[^A-Za-z0-9_\.]', '_')
  $schema = Join-Path $WorkDir "$safe.schema.sql"
  $schemaNoIdx = Join-Path $WorkDir "$safe.no_secondary.sql"
  $prepare = Join-Path $WorkDir "$safe.prepare.sql"
  $frmdumpErr = Join-Path $WorkDir "$safe.frmdump.err.txt"
  $dumpFile = Join-Path $DumpDir "$safe.sql"

  if (Test-TableOk $db $table) {
    $rows = Get-RowCount $db $table
    if ($DumpAlreadyOk) {
      $dumpOut = Dump-RecoveredTable $db $table $dumpFile
      if ($LASTEXITCODE -ne 0) {
        Add-RecoveryLog $entry "FAIL" $rows "Table already readable, but mysqldump failed: $(($dumpOut | Out-String).Trim())"
        continue
      }
    }
    Add-RecoveryLog $entry "ALREADY_OK" $rows "Table already readable and dumped"
    continue
  }

  $env:PYTHONIOENCODING = "utf-8"
  $env:PYTHONUTF8 = "1"
  & $PythonExe $DbsakeRunner frmdump $frm > $schema 2> $frmdumpErr

  if (!(Test-Path $schema) -or ((Get-Item $schema).Length -lt 50)) {
    $errMsg = if (Test-Path $frmdumpErr) { (Get-Content $frmdumpErr -Raw).Trim() } else { "" }
    Add-RecoveryLog $entry "FAIL" "" "frmdump produced no schema: $errMsg"
    continue
  }

  $raw = Get-Content $schema -Raw
  if ($raw -notmatch "CREATE\s+TABLE") {
    Add-RecoveryLog $entry "FAIL" "" "No CREATE TABLE in schema"
    continue
  }

  $patchedSchema = Patch-SchemaForImport $raw
  Set-Content -Path $schemaNoIdx -Value $patchedSchema -Encoding ASCII

  $preparePrefix = @"
SET SESSION sql_mode='';
SET SESSION innodb_strict_mode=OFF;
SET SESSION foreign_key_checks=0;
SET SESSION unique_checks=0;
CREATE DATABASE IF NOT EXISTS ``$db`` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE ``$db``;
DROP TABLE IF EXISTS ``$table``;
"@
  Set-Content -Path $prepare -Value $preparePrefix -Encoding ASCII
  Get-Content $schemaNoIdx | Add-Content -Path $prepare -Encoding ASCII

  $prepareSuffix = @"
ALTER TABLE ``$table`` DISCARD TABLESPACE;
"@
  Add-Content -Path $prepare -Value $prepareSuffix -Encoding ASCII

  $prepOut = Get-Content $prepare -Raw | & $MysqlExe @auth 2>&1
  if ($LASTEXITCODE -ne 0) {
    Add-RecoveryLog $entry "FAIL" "" "Prepare failed: $(($prepOut | Out-String).Trim())"
    continue
  }

  $targetDir = Join-Path $ActiveDataDir $db
  $targetIbd = Join-Path $targetDir "$table.ibd"

  if (!(Test-Path $targetDir)) {
    Add-RecoveryLog $entry "FAIL" "" "Target database folder not created: $targetDir"
    continue
  }

  try {
    Copy-Item $ibd $targetIbd -Force
  } catch {
    Add-RecoveryLog $entry "FAIL" "" "Copy .ibd failed: $($_.Exception.Message)"
    continue
  }

  $importOut = & $MysqlExe @auth -e "SET SESSION sql_mode=''; SET SESSION innodb_strict_mode=OFF; ALTER TABLE $q IMPORT TABLESPACE;" 2>&1
  if ($LASTEXITCODE -ne 0) {
    Add-RecoveryLog $entry "FAIL" "" "Import failed: $(($importOut | Out-String).Trim())"
    continue
  }

  $checkOut = & $MysqlExe @auth -N -e "CHECK TABLE $q;" 2>&1
  if ($LASTEXITCODE -ne 0 -or (($checkOut | Out-String) -notmatch "\sOK\s*$")) {
    Add-RecoveryLog $entry "FAIL" "" "Check failed after import: $(($checkOut | Out-String).Trim())"
    continue
  }

  $rows = Get-RowCount $db $table
  $dumpOut = Dump-RecoveredTable $db $table $dumpFile
  if ($LASTEXITCODE -ne 0) {
    Add-RecoveryLog $entry "FAIL" $rows "Recovered/imported, but mysqldump failed: $(($dumpOut | Out-String).Trim())"
    continue
  }

  Add-RecoveryLog $entry "OK" $rows "Recovered and dumped"
}

Write-Host "Done. Log: $Log"
