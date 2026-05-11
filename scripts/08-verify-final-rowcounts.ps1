# Copyright (c) contributors
# Licensed under the MIT License.
# Adapt paths, credentials, and folder names before running.

param(
  [string]$MysqlExe = "C:\xampp\mysql\bin\mysql.exe",
  [string]$MysqlUser = "root",
  [string]$MysqlPassword = "root",
  [string]$VerifyLog = "C:\dump_import_verify_log.csv",
  [string]$Output = "C:\final_clean_rowcount_verify.csv"
)

$ErrorActionPreference = "Stop"

function Get-AuthArgs {
  $authArgs = @("-u", $MysqlUser)
  if ($MysqlPassword -ne "") {
    $authArgs += "-p$MysqlPassword"
  }
  return $authArgs
}

if (!(Test-Path $VerifyLog)) {
  throw "Verification log not found: $VerifyLog"
}

$auth = Get-AuthArgs
$expected = @{}

Import-Csv $VerifyLog | ForEach-Object {
  if ($_.Table -and $_.ImportedRows -ne "") {
    $expected[$_.Table] = $_.ImportedRows
  }
}

"Table,ExpectedRows,ActualRows,Status" | Set-Content -Path $Output -Encoding ASCII

foreach ($name in $expected.Keys) {
  $db, $table = $name.Split(".", 2)
  $actualOut = & $MysqlExe @auth -N -e "SELECT COUNT(*) FROM ``$db``.``$table``;" 2>&1

  if ($LASTEXITCODE -eq 0) {
    $actual = ($actualOut | Select-Object -First 1).ToString().Trim()
    $status = if ($actual -eq $expected[$name]) { "OK" } else { "MISMATCH" }
  } else {
    $actual = ""
    $status = "FAIL"
  }

  [PSCustomObject]@{
    Table = $name
    ExpectedRows = $expected[$name]
    ActualRows = $actual
    Status = $status
  } | Export-Csv -Path $Output -Append -NoTypeInformation
}

Write-Host "Wrote $Output"
