# 10 — Missing Healthy Databases

The broken-table queue only covers broken tables. Healthy databases might not be recovered by the orphaned-table script because they were never broken.

Compare old folder names with current databases:

```powershell
.\scripts\09-compare-old-and-current-databases.ps1
```

If a missing database folder contains only `db.opt`, it is likely empty. Recreate the database name if needed:

```bat
mysql -u root -proot -e "CREATE DATABASE IF NOT EXISTS missing_db DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

If it contains `.frm` and `.ibd`, recover those tables.

If you made an early healthy dump, import it:

```bat
mysql -u root -proot < C:\healthy_databases.sql
```
