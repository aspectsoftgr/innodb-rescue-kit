# Copyright (c) contributors
# Licensed under the MIT License.
# Adapt paths, credentials, and folder names before running.

param(
  [string]$MysqlExe = "C:\xampp\mysql\bin\mysql.exe",
  [string]$MysqlUser = "root",
  [string]$MysqlPassword = "root"
)

$ErrorActionPreference = "Stop"

function Get-AuthArgs {
  $authArgs = @("-u", $MysqlUser)
  if ($MysqlPassword -ne "") {
    $authArgs += "-p$MysqlPassword"
  }
  return $authArgs
}

$auth = Get-AuthArgs
$verifyDbs = & $MysqlExe @auth -N -e "SHOW DATABASES LIKE 'verify_%';"

foreach ($db in $verifyDbs) {
  Write-Host "Dropping $db"
  & $MysqlExe @auth -e "DROP DATABASE ``$db``;"
}
