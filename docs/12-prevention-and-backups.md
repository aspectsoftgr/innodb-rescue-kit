# 12 — Prevention and Backups

Recommended durability settings:

```ini
[mysqld]
default_storage_engine=InnoDB
innodb_flush_log_at_trx_commit=1
innodb_doublewrite=1
sync_binlog=1
aria_recover_options=BACKUP,QUICK,FORCE
```

Use a UPS.

Create daily SQL backups:

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

Test restores regularly.
