# Copyright (c) contributors
# Licensed under the MIT License.
# Adapt paths, credentials, and folder names before running.

param(
  [string]$MysqlExe = "C:\xampp\mysql\bin\mysql.exe",
  [string]$MysqlDumpExe = "C:\xampp\mysql\bin\mysqldump.exe",
  [string]$MysqlUser = "root",
  [string]$MysqlPassword = "root",
  [string]$RecoveryLog = "C:\ibd_recovery_log.csv",
  [string]$OutputDir = "C:\ibd_recovery_checkfailed_salvage",
  [string]$OutputLog = "C:\checkfailed_salvage_log.csv"
)

$ErrorActionPreference = "Stop"

function Get-AuthArgs {
  $authArgs = @("-u", $MysqlUser)
  if ($MysqlPassword -ne "") {
    $authArgs += "-p$MysqlPassword"
  }
  return $authArgs
}

if (!(Test-Path $RecoveryLog)) {
  throw "Recovery log not found: $RecoveryLog"
}

$auth = Get-AuthArgs
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
"Table,SelectCount,DumpResult,Message" | Set-Content -Path $OutputLog -Encoding ASCII

$tables = Import-Csv $RecoveryLog |
  Where-Object { $_.Status -eq "FAIL" -and $_.Message -like "Check failed after import*" }

foreach ($row in $tables) {
  $name = $row.Table
  $db, $table = $name.Split(".", 2)
  $q = "``$db``.``$table``"
  $dump = Join-Path $OutputDir "$db.$table.sql"

  Write-Host "Testing $name"

  $countOut = & $MysqlExe @auth -N -e "SELECT COUNT(*) FROM $q;" 2>&1

  if ($LASTEXITCODE -eq 0) {
    $count = ($countOut | Select-Object -First 1).ToString().Trim()
    & $MysqlDumpExe @auth $db $table --skip-lock-tables --quick "--result-file=$dump" 2>&1 | Out-File "$dump.err.txt"
    $dumpOk = if ($LASTEXITCODE -eq 0) { "OK" } else { "FAIL" }
    $msg = if ($dumpOk -eq "OK") { "Dumped despite CHECK warning" } else { Get-Content "$dump.err.txt" -Raw }
  } else {
    $count = ""
    $dumpOk = "SKIP"
    $msg = ($countOut | Out-String)
  }

  [PSCustomObject]@{
    Table = $name
    SelectCount = $count
    DumpResult = $dumpOk
    Message = $msg.Trim()
  } | Export-Csv -Path $OutputLog -Append -NoTypeInformation
}

Write-Host "Wrote $OutputLog"
