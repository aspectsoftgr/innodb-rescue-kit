# 00 — Incident Overview

This kit targets a failure mode where MariaDB/XAMPP starts partially or not at all after a crash, and application tables fail with:

```text
Table 'database.table' doesn't exist in engine
```

The files may still exist:

```text
database\table.frm
database\table.ibd
```

The `.frm` file contains the table definition. The `.ibd` file contains InnoDB table data. The problem is that InnoDB's internal dictionary no longer has a usable record for the table.

The safest path is to recover each table into SQL, verify the SQL, and rebuild a clean MariaDB data folder from those verified dumps.
