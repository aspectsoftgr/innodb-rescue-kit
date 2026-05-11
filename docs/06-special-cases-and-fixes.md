# 06 — Special Cases and Fixes

## Missing `.cfg`

Error:

```text
ERROR 1815: Drop all secondary indexes before importing table when .cfg file is missing
```

Fix: remove secondary indexes and foreign keys before import. Keep the primary key.

## Invalid timestamp/datetime defaults

Patch:

```sql
`col` timestamp DEFAULT NULL
```

to:

```sql
`col` timestamp NULL DEFAULT NULL
```

The bulk script includes this patch.

## dbsake BLOB/LONG_BLOB crash

Error:

```text
Unpack method not implemented for <MySQLType.BLOB>
Unpack method not implemented for <MySQLType.LONG_BLOB>
```

Use `scripts/03-dbsake-blobfix-runner.py`.

## Windows Unicode output error

Error:

```text
UnicodeEncodeError: 'charmap' codec can't encode characters
```

Fix:

```powershell
$env:PYTHONIOENCODING = "utf-8"
$env:PYTHONUTF8 = "1"
```

## Invalid decoded defaults

Sometimes a decoded default is too long for the column, for example:

```sql
`col` varchar(5) NOT NULL DEFAULT '??????'
```

Since defaults do not matter for importing existing rows, patch to:

```sql
DEFAULT ''
```

The bulk script includes a general `varchar(n)` default-length patch.
