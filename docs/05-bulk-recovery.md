# 05 — Bulk Recovery

After one-table recovery succeeds, run the bulk script.

```powershell
$env:PYTHONIOENCODING = "utf-8"
$env:PYTHONUTF8 = "1"

.\scripts\04-recover-orphaned-ibd-tables.ps1 `
  -BrokenList C:\broken_tables_exact.txt `
  -OldDataDir C:\xampp\mysql\data_orphaned_for_recovery `
  -ActiveDataDir C:\xampp\mysql\data
```

Status values:

```text
OK          recovered and dumped
ALREADY_OK already readable, optionally dumped
FAIL        needs special handling
SKIP        missing source files
```

Output:

```text
C:\ibd_recovery_work
C:\ibd_recovery_dumps
C:\ibd_recovery_log.csv
```
