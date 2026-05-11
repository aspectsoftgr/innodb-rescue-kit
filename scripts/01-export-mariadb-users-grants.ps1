# Copyright (c) contributors
# Licensed under the MIT License.
# Adapt paths, credentials, and folder names before running.

param(
  [string]$MysqlExe = "C:\xampp\mysql\bin\mysql.exe",
  [string]$MysqlUser = "root",
  [string]$MysqlPassword = "root",
  [string]$Output = "C:\mariadb_users_grants.sql",
  [string]$ErrorLog = "C:\mariadb_users_grants_errors.txt"
)

$ErrorActionPreference = "Stop"

function Get-AuthArgs {
  $authArgs = @("-u", $MysqlUser)
  if ($MysqlPassword -ne "") {
    $authArgs += "-p$MysqlPassword"
  }
  return $authArgs
}

if (!(Test-Path $MysqlExe)) {
  throw "mysql.exe not found: $MysqlExe"
}

$auth = Get-AuthArgs

"-- MariaDB users/grants exported with SHOW GRANTS" | Set-Content -Path $Output -Encoding ASCII
"-- Do not edit unless you know exactly what you are doing." | Add-Content -Path $Output -Encoding ASCII
"SET SQL_LOG_BIN=0;" | Add-Content -Path $Output -Encoding ASCII
"SET SESSION sql_mode='';" | Add-Content -Path $Output -Encoding ASCII
"" | Set-Content -Path $ErrorLog -Encoding ASCII

$accounts = & $MysqlExe @auth -N -B -e "SELECT User, Host FROM mysql.global_priv ORDER BY User, Host;" 2>> $ErrorLog

foreach ($line in $accounts) {
  if ([string]::IsNullOrWhiteSpace($line)) {
    continue
  }

  $parts = $line -split "`t"
  if ($parts.Count -lt 2) {
    "Could not parse account line: $line" | Add-Content -Path $ErrorLog -Encoding ASCII
    continue
  }

  # Avoid PowerShell's built-in read-only host variable name.
  $accountUser = $parts[0]
  $accountHost = $parts[1]

  $u = $accountUser.Replace("'", "''")
  $h = $accountHost.Replace("'", "''")

  "" | Add-Content -Path $Output -Encoding ASCII
  "-- Grants for '$u'@'$h'" | Add-Content -Path $Output -Encoding ASCII

  $grants = & $MysqlExe @auth -N -B -e "SHOW GRANTS FOR '$u'@'$h';" 2>> $ErrorLog

  if ($LASTEXITCODE -ne 0 -or $null -eq $grants) {
    "-- FAILED TO EXPORT GRANTS FOR '$u'@'$h'" | Add-Content -Path $Output -Encoding ASCII
    "FAILED TO EXPORT GRANTS FOR '$u'@'$h'" | Add-Content -Path $ErrorLog -Encoding ASCII
    continue
  }

  foreach ($grant in $grants) {
    if (![string]::IsNullOrWhiteSpace($grant)) {
      "$grant;" | Add-Content -Path $Output -Encoding ASCII
    }
  }
}

"" | Add-Content -Path $Output -Encoding ASCII
"FLUSH PRIVILEGES;" | Add-Content -Path $Output -Encoding ASCII

Write-Host "Wrote grants file: $Output"
Write-Host "Error log: $ErrorLog"
