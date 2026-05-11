# 13 — Best Practices Checklist

Use this checklist before publishing or running the kit.

## Before recovery

- [ ] Stop MariaDB cleanly if possible.
- [ ] Work on a copy of the data directory.
- [ ] Keep the original old data folder unchanged.
- [ ] Record MariaDB/XAMPP versions.
- [ ] Export any users/grants if the server can start.

## During recovery

- [ ] Prove the method on one table first.
- [ ] Remove secondary indexes when `.cfg` is missing.
- [ ] Dump every recovered or already-readable table.
- [ ] Treat CHECK-failed tables as unsafe unless their SQL dumps verify cleanly.
- [ ] Keep logs from every run.

## Verification

- [ ] Every queued table has a dump or a documented reason.
- [ ] Dumps import into fresh verification databases.
- [ ] Row counts match.
- [ ] `mysqlcheck` on verification databases is clean.
- [ ] Final clean server is rebuilt from verified dumps, not raw `.ibd` files.
- [ ] Users/grants are restored from `SHOW GRANTS`.

## After recovery

- [ ] Final `mysqlcheck --all-databases` is clean.
- [ ] Final full SQL dump exists.
- [ ] Backups are copied off-machine.
- [ ] Old recovery folders are archived before deletion.
- [ ] Automated backups are scheduled and tested.
