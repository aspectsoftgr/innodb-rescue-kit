# 09 — Clean Rebuild and User Grants

After dump verification, rebuild a fresh MariaDB data directory.

## Export users/grants

```powershell
.\scripts\01-export-mariadb-users-grants.ps1
```

This uses `SHOW GRANTS`, not raw copying of `mysql` system tables.

## Create fresh data folder

```bat
taskkill /F /IM mysqld.exe
cd /d C:\xampp\mysql
ren data data_recovery_workspace_final
mkdir data
xcopy C:\xampp\mysql\backup C:\xampp\mysql\data /E /I /H /K /Y
```

Start MariaDB.

## Import verified dumps

```powershell
.\scripts\07-import-verified-dumps-to-clean-server.ps1
```

## Restore users/grants

```bat
cd /d C:\xampp\mysql\bin
mysql -u root -proot < C:\mariadb_users_grants.sql
```

## Verify row counts

```powershell
.\scripts\08-verify-final-rowcounts.ps1
```

## Final mysqlcheck

```bat
mysqlcheck -u root -proot --all-databases > C:\final_clean_mysqlcheck.txt
```
