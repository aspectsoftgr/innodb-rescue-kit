# 04 — Single Table Recovery

Prove the method on one table before bulk recovery.

## Extract schema

```bat
C:\Python3\python.exe C:\tools\dbsake frmdump C:\xampp\mysql\data_orphaned_for_recovery\mydb\mytable.frm > C:\mytable_schema.sql
```

If dbsake fails on BLOB/LONG_BLOB metadata, use:

```bat
C:\Python3\python.exe .\scripts\03-dbsake-blobfix-runner.py frmdump C:\xampp\mysql\data_orphaned_for_recovery\mydb\mytable.frm > C:\mytable_schema.sql
```

## Remove secondary indexes

Keep:

```sql
PRIMARY KEY (...)
```

Remove:

```sql
KEY ...
UNIQUE KEY ...
FULLTEXT KEY ...
SPATIAL KEY ...
CONSTRAINT ...
FOREIGN KEY ...
```

This avoids:

```text
Drop all secondary indexes before importing table when .cfg file is missing
```

## Prepare target table

```sql
CREATE DATABASE IF NOT EXISTS `mydb`;
USE `mydb`;
DROP TABLE IF EXISTS `mytable`;
CREATE TABLE `mytable` (... PRIMARY KEY (...)) ENGINE=InnoDB;
ALTER TABLE `mytable` DISCARD TABLESPACE;
```

## Copy old `.ibd` and import

```bat
taskkill /F /IM mysqld.exe
copy /Y C:\xampp\mysql\data_orphaned_for_recovery\mydb\mytable.ibd C:\xampp\mysql\data\mydb\mytable.ibd
```

Start MariaDB, then:

```bat
mysql -u root -proot -e "ALTER TABLE mydb.mytable IMPORT TABLESPACE;"
mysql -u root -proot -e "CHECK TABLE mydb.mytable;"
mysql -u root -proot -e "SELECT COUNT(*) FROM mydb.mytable;"
mysqldump -u root -proot mydb mytable --single-transaction --quick --result-file="C:\recovered_mydb.mytable.sql"
```
