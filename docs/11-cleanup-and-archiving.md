# 11 — Cleanup and Archiving

Delete temporary files only after:

- all dumps verify,
- final row counts match,
- final mysqlcheck is clean,
- final full SQL backup exists,
- external backups exist,
- applications have been tested.

Safe temporary cleanup examples:

```bat
rmdir /S /Q C:\ibd_recovery_work
del C:\verify_import_*.sql
del C:\remaining_recovery_failures.txt
```

Archive rather than immediately delete:

```text
original data directory
recovery workspace
orphaned source directory
```

Always keep externally:

```text
final_clean_all_databases.sql
mariadb_users_grants.sql
ibd_recovery_dumps
ibd_recovery_checkfailed_salvage
verification logs
final mysqlcheck log
```
