# Copyright (c) contributors
# Licensed under the MIT License.
# Adapt paths, credentials, and folder names before running.

param(
  [string]$MysqlcheckOutput = "C:\mariadb_check_all.txt",
  [string]$Output = "C:\broken_tables_exact.txt"
)

$ErrorActionPreference = "Stop"

if (!(Test-Path $MysqlcheckOutput)) {
  throw "mysqlcheck output not found: $MysqlcheckOutput"
}

Select-String -Path $MysqlcheckOutput -Pattern "Table '([^']+)' doesn't exist in engine" |
  ForEach-Object { $_.Matches[0].Groups[1].Value } |
  Sort-Object -Unique |
  Set-Content -Path $Output -Encoding ASCII

$count = (Get-Content $Output -ErrorAction SilentlyContinue | Where-Object { $_.Trim() -ne "" }).Count
Write-Host "Wrote $Output with $count table(s)."
