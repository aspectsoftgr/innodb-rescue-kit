# Copyright (c) contributors
# Licensed under the MIT License.
# Adapt paths, credentials, and folder names before running.

param(
  [string]$CheckFile = "C:\final_clean_mysqlcheck.txt"
)

$ErrorActionPreference = "Stop"

if (!(Test-Path $CheckFile)) {
  throw "mysqlcheck output file not found: $CheckFile"
}

Select-String -Path $CheckFile -Pattern "error|corrupt|warning|failed|doesn't exist|does not exist|crashed" -CaseSensitive:$false
