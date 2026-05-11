# Backup Commands

## Manual full backup

```bat
cd /d C:\xampp\mysql\bin

mysqldump -u root -proot ^
  --all-databases ^
  --routines ^
  --events ^
  --triggers ^
  --single-transaction ^
  --quick ^
  --result-file="D:\mariadb_backups\all_databases.sql"
```

## Scheduled PowerShell backup

```powershell
$backupDir = "D:\mariadb_backups"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
$stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$out = Join-Path $backupDir "mariadb_all_$stamp.sql"

& C:\xampp\mysql\bin\mysqldump.exe -u root -proot `
  --all-databases `
  --routines `
  --events `
  --triggers `
  --single-transaction `
  --quick `
  "--result-file=$out"
```
