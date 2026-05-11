# Copyright (c) contributors
# Licensed under the MIT License.
# Verifies that every table in the broken-table queue has either a normal dump or a salvage dump.

param(
  [string]$BrokenList = "C:\broken_tables_exact.txt",
  [string]$DumpDir = "C:\ibd_recovery_dumps",
  [string]$SalvageDumpDir = "C:\ibd_recovery_checkfailed_salvage",
  [string]$Output = "C:\missing_recovered_dumps.txt"
)

$ErrorActionPreference = "Stop"

if (!(Test-Path $BrokenList)) {
  throw "Broken table list not found: $BrokenList"
}

$tables = Get-Content $BrokenList |
  ForEach-Object { $_.Trim() } |
  Where-Object { $_ -ne "" }

$missing = foreach ($table in $tables) {
  $mainDump = Join-Path $DumpDir "$table.sql"
  $salvageDump = Join-Path $SalvageDumpDir "$table.sql"

  if (!(Test-Path $mainDump) -and !(Test-Path $salvageDump)) {
    $table
  }
}

$missing | Set-Content -Path $Output -Encoding ASCII

Write-Host "Broken table count: $($tables.Count)"
Write-Host "Missing dump count: $($missing.Count)"
Write-Host "Missing list: $Output"
