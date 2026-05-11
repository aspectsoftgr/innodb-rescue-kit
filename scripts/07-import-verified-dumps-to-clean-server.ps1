# Copyright (c) contributors
# Licensed under the MIT License.
# Adapt paths, credentials, and folder names before running.

param(
  [string]$MysqlExe = "C:\xampp\mysql\bin\mysql.exe",
  [string]$MysqlUser = "root",
  [string]$MysqlPassword = "root",
  [string]$DumpDir = "C:\ibd_recovery_dumps",
  [string]$SalvageDumpDir = "C:\ibd_recovery_checkfailed_salvage",
  [string]$ImportLog = "C:\final_clean_import_log.csv"
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
"Table,Status,Message" | Set-Content -Path $ImportLog -Encoding ASCII

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

foreach ($file in $files) {
  $base = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
  $parts = $base.Split(".", 2)

  if ($parts.Count -ne 2) {
    continue
  }

  $db = $parts[0]
  $table = $parts[1]

  Write-Host "Importing $db.$table"

  & $MysqlExe @auth -e "SET SESSION sql_mode=''; CREATE DATABASE IF NOT EXISTS ``$db`` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  if ($LASTEXITCODE -ne 0) {
    [PSCustomObject]@{ Table = "$db.$table"; Status = "FAIL"; Message = "Could not create database" } |
      Export-Csv -Path $ImportLog -Append -NoTypeInformation
    continue
  }

  $cmd = "`"$MysqlExe`" $cmdAuth --default-character-set=utf8mb4 `"$db`" < `"$($file.FullName)`""
  cmd.exe /c $cmd

  if ($LASTEXITCODE -eq 0) {
    [PSCustomObject]@{ Table = "$db.$table"; Status = "OK"; Message = "Imported" } |
      Export-Csv -Path $ImportLog -Append -NoTypeInformation
  } else {
    [PSCustomObject]@{ Table = "$db.$table"; Status = "FAIL"; Message = "Import failed" } |
      Export-Csv -Path $ImportLog -Append -NoTypeInformation
  }
}

Write-Host "Wrote $ImportLog"
