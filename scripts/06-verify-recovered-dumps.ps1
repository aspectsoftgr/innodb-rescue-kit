# Copyright (c) contributors
# Licensed under the MIT License.
# Adapt paths, credentials, and folder names before running.

param(
  [string]$MysqlExe = "C:\xampp\mysql\bin\mysql.exe",
  [string]$MysqlUser = "root",
  [string]$MysqlPassword = "root",
  [string]$DumpDir = "C:\ibd_recovery_dumps",
  [string]$SalvageDumpDir = "C:\ibd_recovery_checkfailed_salvage",
  [string]$RecoveryLog = "C:\ibd_recovery_log.csv",
  [string]$SalvageLog = "C:\checkfailed_salvage_log.csv",
  [string]$VerifyLog = "C:\dump_import_verify_log.csv"
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

$auth = Get-AuthArgs
$cmdAuth = Get-CmdAuthFragment
$expected = @{}

if (Test-Path $RecoveryLog) {
  Import-Csv $RecoveryLog | ForEach-Object {
    if ($_.Status -in @("OK", "ALREADY_OK") -and $_.Rows -ne "") {
      $expected[$_.Table] = $_.Rows
    }
  }
}

if (Test-Path $SalvageLog) {
  Import-Csv $SalvageLog | ForEach-Object {
    if ($_.DumpResult -eq "OK" -and $_.SelectCount -ne "") {
      $expected[$_.Table] = $_.SelectCount
    }
  }
}

$files = @()
$files += Get-ChildItem $DumpDir -Filter *.sql -ErrorAction SilentlyContinue
$files += Get-ChildItem $SalvageDumpDir -Filter *.sql -ErrorAction SilentlyContinue

$files = $files |
  Group-Object BaseName |
  ForEach-Object {
    $_.Group |
      Sort-Object { if ($_.FullName -like "*$SalvageDumpDir*") { 0 } else { 1 } } |
      Select-Object -First 1
  }

"Table,ExpectedRows,ImportedRows,ImportStatus,CountStatus,Message" | Set-Content -Path $VerifyLog -Encoding ASCII

foreach ($file in $files) {
  $base = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
  $parts = $base.Split(".", 2)

  if ($parts.Count -ne 2) {
    continue
  }

  $db = $parts[0]
  $table = $parts[1]
  $verifyDb = "verify_$db"
  $fullName = "$db.$table"

  Write-Host "Verifying $fullName"

  & $MysqlExe @auth -e "SET SESSION sql_mode=''; SET SESSION foreign_key_checks=0; CREATE DATABASE IF NOT EXISTS ``$verifyDb`` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
  if ($LASTEXITCODE -ne 0) {
    [PSCustomObject]@{
      Table = $fullName
      ExpectedRows = if ($expected.ContainsKey($fullName)) { $expected[$fullName] } else { "" }
      ImportedRows = ""
      ImportStatus = "FAIL"
      CountStatus = "UNKNOWN"
      Message = "Could not create verification database $verifyDb"
    } | Export-Csv -Path $VerifyLog -Append -NoTypeInformation
    continue
  }

  $cmd = "`"$MysqlExe`" $cmdAuth --default-character-set=utf8mb4 `"$verifyDb`" < `"$($file.FullName)`""
  cmd.exe /c $cmd
  $importOk = ($LASTEXITCODE -eq 0)

  if ($importOk) {
    $countOut = & $MysqlExe @auth -N -e "SELECT COUNT(*) FROM ``$verifyDb``.``$table``;" 2>&1
    $importedRows = if ($LASTEXITCODE -eq 0) { ($countOut | Select-Object -First 1).ToString().Trim() } else { "" }
    $expectedRows = if ($expected.ContainsKey($fullName)) { $expected[$fullName] } else { "" }
    $countStatus = if ($expectedRows -eq "" -or $expectedRows -eq $importedRows) { "OK" } else { "MISMATCH" }

    [PSCustomObject]@{
      Table = $fullName
      ExpectedRows = $expectedRows
      ImportedRows = $importedRows
      ImportStatus = "OK"
      CountStatus = $countStatus
      Message = ""
    } | Export-Csv -Path $VerifyLog -Append -NoTypeInformation
  } else {
    [PSCustomObject]@{
      Table = $fullName
      ExpectedRows = if ($expected.ContainsKey($fullName)) { $expected[$fullName] } else { "" }
      ImportedRows = ""
      ImportStatus = "FAIL"
      CountStatus = "UNKNOWN"
      Message = "Dump import failed"
    } | Export-Csv -Path $VerifyLog -Append -NoTypeInformation
  }
}

Write-Host "Wrote $VerifyLog"
