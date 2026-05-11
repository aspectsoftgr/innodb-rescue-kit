# Troubleshooting

## `Access denied for user 'root'@'localhost'`

Use the correct password or reset root in a controlled maintenance window.

## `ERROR 1815`

Drop secondary indexes before import.

## `Invalid default value`

Patch timestamp/datetime/default definitions.

## `dbsake` BLOB/LONG_BLOB failure

Use the blobfix runner.

## `UnicodeEncodeError`

Set UTF-8 environment variables.

## `CHECK TABLE` says corrupt

Try `SELECT COUNT(*)`; if it works, dump with `--skip-lock-tables --quick` and verify the dump.
