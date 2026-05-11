# InnoDB Rescue Kit

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

A practical, general-purpose recovery runbook and script kit for Windows XAMPP MariaDB/MySQL incidents where InnoDB tables still exist on disk as `.frm` + `.ibd` files, but MariaDB reports:

```text
ERROR 1932 (42S02): Table 'database.table' doesn't exist in engine
ERROR 1815 (HY000): Drop all secondary indexes before importing table ... when .cfg file is missing
```

> **Data-loss warning:** this kit is for advanced recovery work. Always work from copies, never from your only data directory.

## What InnoDB Rescue Kit does

It documents and automates the recovery path:

```text
old .frm + old .ibd
→ recreate table in clean MariaDB
→ remove secondary indexes when .cfg is missing
→ DISCARD TABLESPACE
→ copy old .ibd
→ IMPORT TABLESPACE
→ dump table to SQL
→ verify SQL dump by re-import
→ rebuild a fresh clean MariaDB instance from verified SQL
```

## What InnoDB Rescue Kit does not promise

This is not a magic InnoDB repair tool. It cannot guarantee recovery from physically destroyed pages, missing `.ibd` files, or incompatible schemas. It is designed for the practical orphaned-table scenario where `.frm` and `.ibd` files are still available.

## Covered recovery stages

- Startup/system-table triage.
- Preserving the original data folder.
- Identifying `doesn't exist in engine` tables.
- Single-table proof recovery.
- Bulk orphaned `.ibd` recovery.
- Missing `.cfg` / secondary-index workaround.
- Invalid timestamp/default-value patching.
- `dbsake` BLOB/LONG_BLOB workaround.
- Windows UTF-8 / `UnicodeEncodeError` workaround.
- Salvage dumps for `CHECK TABLE` corrupt-but-readable tables.
- SQL dump verification by fresh import and row-count matching.
- Clean final rebuild from verified dumps.
- MariaDB users/grants export and restore.
- Missing healthy database comparison.
- Final `mysqlcheck`, backup, cleanup, and prevention.

## Quick start

Read these first:

1. [`docs/01-triage-and-safety.md`](docs/01-triage-and-safety.md)
2. [`docs/04-single-table-recovery.md`](docs/04-single-table-recovery.md)
3. [`docs/05-bulk-recovery.md`](docs/05-bulk-recovery.md)
4. [`docs/08-verify-recovered-dumps.md`](docs/08-verify-recovered-dumps.md)
5. [`docs/09-clean-rebuild-and-user-grants.md`](docs/09-clean-rebuild-and-user-grants.md)

Then adapt the paths in [`scripts/00-config-template.ps1`](scripts/00-config-template.ps1).

## Typical script order

```powershell
# 1. Generate broken-table queue from mysqlcheck output
.\scripts\02-generate-broken-table-queue.ps1

# 2. Export MariaDB users/grants before clean rebuild
.\scripts\01-export-mariadb-users-grants.ps1

# 3. Recover orphaned .ibd tables to SQL dumps
.\scripts\04-recover-orphaned-ibd-tables.ps1

# 4. Salvage tables that imported but failed CHECK TABLE
.\scripts\05-salvage-checkfailed-tables.ps1

# 5. Verify all recovered SQL dumps
.\scripts\06-verify-recovered-dumps.ps1

# 6. Confirm every queued table has a dump
.\scripts\12-check-dump-coverage.ps1

# 7. Import verified dumps into a fresh clean server
.\scripts\07-import-verified-dumps-to-clean-server.ps1

# 8. Verify final row counts
.\scripts\08-verify-final-rowcounts.ps1
```

## Validation

This repo includes:

- `tests/validate_repository.py` for static repository checks.
- `.github/workflows/validate.yml` for Windows PowerShell parser validation on GitHub Actions.
- `VALIDATION_REPORT.md` generated from the latest audit pass.

## Recommended final success criteria

A recovery is not complete until:

```text
all expected dumps exist
all dumps import into fresh verification databases
row counts match
mysqlcheck on verification databases is clean
fresh final MariaDB is rebuilt from verified dumps
users/grants are restored
final mysqlcheck is clean
final full SQL backup exists
```

## License

MIT. See [`LICENSE`](LICENSE).
