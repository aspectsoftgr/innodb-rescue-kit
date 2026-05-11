# 01 — Triage and Safety

## Stop MariaDB

Stop from XAMPP Control Panel or run:

```bat
taskkill /F /IM mysqld.exe
```

## Preserve the original data folder

Do not operate on the only copy.

```bat
cd /d C:\xampp\mysql
ren data data_original_do_not_touch
```

or copy it to an external drive:

```bat
xcopy C:\xampp\mysql\data D:\mysql_data_original_backup /E /I /H /K
```

## Files not to delete during recovery

```text
ibdata1
ib_logfile*
aria_log*
*.frm
*.ibd
*.MAD
*.MAI
*.cfg, if present
```

## Recommended recovery layout

```text
C:\xampp\mysql\data                         active clean recovery target
C:\xampp\mysql\data_orphaned_for_recovery   old source files
C:\ibd_recovery_dumps                        recovered SQL dumps
C:\ibd_recovery_checkfailed_salvage           salvage SQL dumps
```

## Dump healthy databases early if possible

If MariaDB starts enough to dump healthy databases, dump them before deeper recovery:

```bat
cd /d C:\xampp\mysql\bin

mysqldump -u root -proot ^
  --databases db1 db2 ^
  --routines ^
  --events ^
  --triggers ^
  --single-transaction ^
  --quick ^
  --result-file="C:\healthy_databases.sql"
```
