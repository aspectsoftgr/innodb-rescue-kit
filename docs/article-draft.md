# Recovering Orphaned InnoDB Tables in XAMPP/MariaDB After a Crash

A MariaDB crash can leave a database in a strange state: table files still exist on disk, but the storage engine says the tables do not exist. The key message is:

```text
Table 'database.table' doesn't exist in engine
```

When `.frm` and `.ibd` files are still present, recovery may be possible. The reliable approach is not to copy the old folder into a new server. Instead, recreate each table structure, import the old `.ibd`, dump the rows to SQL, verify those dumps, and rebuild a clean database from the verified SQL.

The process has several traps: missing `.cfg` files, secondary indexes, invalid defaults, dbsake parser limitations, Windows encoding errors, and tables that import but fail `CHECK TABLE`. This kit documents each stage and includes scripts to handle the common cases.

The final goal is a clean MariaDB data folder and a final full SQL backup, not a fragile imported InnoDB workspace.
