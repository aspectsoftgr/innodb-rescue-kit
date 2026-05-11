# 03 — Identify Broken Tables

Run a check:

```bat
cd /d C:\xampp\mysql\bin
mysqlcheck -u root -proot --all-databases > C:\mariadb_check_all.txt
```

Create a queue file:

```powershell
.\scripts\02-generate-broken-table-queue.ps1 `
  -MysqlcheckOutput C:\mariadb_check_all.txt `
  -Output C:\broken_tables_exact.txt
```

Queue format:

```text
database.table
database.table2
```

For one entry, confirm source files exist:

```powershell
dir C:\xampp\mysql\data_orphaned_for_recovery\database\table.*
```

You need at least `.frm` and `.ibd` for this workflow.
