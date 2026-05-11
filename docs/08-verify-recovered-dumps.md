# 08 — Verify Recovered Dumps

Run:

```powershell
.\scripts\06-verify-recovered-dumps.ps1
```

Summarize:

```powershell
Import-Csv C:\dump_import_verify_log.csv |
  Group-Object ImportStatus, CountStatus |
  Select-Object Name, Count
```

Best result:

```text
OK, OK  <all tables>
```

Run `mysqlcheck` on verification databases:

```powershell
$verifyDbs = & C:\xampp\mysql\bin\mysql.exe -u root -proot -N -e "SHOW DATABASES LIKE 'verify_%';"
$results = foreach ($db in $verifyDbs) {
  & C:\xampp\mysql\bin\mysqlcheck.exe -u root -proot --databases $db
}
$results | Out-File C:\verify_mysqlcheck.txt

Select-String -Path C:\verify_mysqlcheck.txt -Pattern "error|corrupt|warning|failed|doesn't exist" -CaseSensitive:$false
```

Expected: no output from `Select-String`.


## Check dump coverage

Before verifying imports, confirm that every table in the queue has either a normal dump or a salvage dump:

```powershell
.\scripts\12-check-dump-coverage.ps1
```

Expected:

```text
Missing dump count: 0
```
