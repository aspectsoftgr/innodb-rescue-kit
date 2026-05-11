# 07 — Salvage CHECK-Failed Tables

Some tables import but fail:

```text
CHECK TABLE ... Corrupt
B-tree of index PRIMARY is corrupted
B-tree of index GEN_CLUST_INDEX is corrupted
```

Try reading them anyway:

```bat
mysql -u root -proot -e "SELECT COUNT(*) FROM mydb.mytable;"
```

If readable, dump immediately:

```bat
mysqldump -u root -proot mydb mytable --skip-lock-tables --quick --result-file="C:\ibd_recovery_checkfailed_salvage\mydb.mytable.sql"
```

Then verify the salvage dump by re-importing it into a fresh verification database.
