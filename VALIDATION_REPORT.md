# Validation Report

Generated: 2026-05-09T21:43:13.333666+00:00

## Final audit summary

- PASS: Python wrapper compiled with `py_compile`.
- PASS: Repository static validation passed.
- PASS: Markdown fenced-code blocks are balanced.
- PASS: PowerShell scripts passed text-level checks for `$Host` variable collisions, here-string hazards, and missing param blocks (except the config template).
- PASS: No original incident-specific database names were found.
- PASS: No Python cache files are included in the repository package.
- PASS: Bulk recovery dumps already-readable tables by default and logs dump failures as failures.
- PASS: MIT license, security policy, contribution guide, issue templates, and disclaimer are included.
- INFO: PowerShell is not installed in this execution environment; GitHub Actions performs true parser validation on `windows-latest`.

## Best-practice review

The repository was reviewed against the recovery process and the included scripts cover:

- safety-first copy/working-directory workflow,
- broken table queue generation,
- users/grants export,
- `.frm` schema extraction,
- missing `.cfg` / secondary-index workaround,
- invalid default handling,
- BLOB/LONG_BLOB `dbsake` workaround,
- UTF-8/Windows output handling,
- corrupt-but-dumpable table salvage,
- dump coverage checking,
- verification imports and row-count comparison,
- final clean import,
- final row-count verification,
- old/current database comparison,
- verification database cleanup,
- mysqlcheck output scanning.

## Execution limitation

The scripts were not executed against a live MariaDB server in this environment. They were statically audited and the Python helper was compiled. The included GitHub Actions workflow validates PowerShell parser syntax on Windows and runs `PSScriptAnalyzer`.
