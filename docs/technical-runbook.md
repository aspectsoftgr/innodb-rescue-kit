# Technical Runbook

Follow these stages in order:

1. Stop MariaDB.
2. Preserve the original data directory.
3. Repair startup/system-table issues only if needed to access metadata or export users.
4. Generate a broken-table queue from `mysqlcheck` output.
5. Prove recovery on one table.
6. Run bulk recovery.
7. Run salvage for CHECK-failed tables.
8. Verify all dumps by importing into verification databases.
9. Export users/grants.
10. Create a fresh clean MariaDB data folder.
11. Import verified dumps.
12. Restore users/grants.
13. Verify final row counts.
14. Run final `mysqlcheck`.
15. Create final full SQL backup.
16. Archive old folders and recovery logs.

See the numbered docs for commands and details.
