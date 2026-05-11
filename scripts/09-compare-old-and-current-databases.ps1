# Copyright (c) contributors
# Licensed under the MIT License.
# Adapt paths, credentials, and folder names before running.

param(
  [string]$MysqlExe = "C:\xampp\mysql\bin\mysql.exe",
  [string]$MysqlUser = "root",
  [string]$MysqlPassword = "root",
  [string]$OldDataDir = "C:\xampp\mysql\data_orphaned_for_recovery"
)

$ErrorActionPreference = "Stop"

function Get-AuthArgs {
  $authArgs = @("-u", $MysqlUser)
  if ($MysqlPassword -ne "") {
    $authArgs += "-p$MysqlPassword"
  }
  return $authArgs
}

if (!(Test-Path $OldDataDir)) {
  throw "Old data directory not found: $OldDataDir"
}

$auth = Get-AuthArgs
$systemDbs = @("information_schema", "mysql", "performance_schema", "phpmyadmin", "test")

$current = & $MysqlExe @auth -N -e "SHOW DATABASES;" |
  Where-Object { $_ -notin $systemDbs }

$old = Get-ChildItem $OldDataDir -Directory |
  Select-Object -ExpandProperty Name |
  Where-Object { $_ -notin $systemDbs }

$missing = $old | Where-Object { $_ -notin $current }

"Current databases:"
$current
""
"Databases present in old folder but missing now:"
$missing
