# 02 — Startup and System Table Repair

Run MariaDB directly to reveal the real startup error:

```bat
cd /d C:\xampp\mysql\bin
mysqld --defaults-file="C:\xampp\mysql\bin\my.ini" --console
```

A common blocker is a corrupt MariaDB system table:

```text
Index for table '.\mysql\db' is corrupt
Fatal error: Can't open and lock privilege tables
```

For XAMPP, clean system-table files may exist in:

```text
C:\xampp\mysql\backup\mysql
```

Example repair for `mysql.db` after backing up the broken files:

```bat
copy /Y C:\xampp\mysql\data\mysql\db.frm C:\xampp\mysql\data\mysql\db.frm.broken
copy /Y C:\xampp\mysql\data\mysql\db.MAD C:\xampp\mysql\data\mysql\db.MAD.broken
copy /Y C:\xampp\mysql\data\mysql\db.MAI C:\xampp\mysql\data\mysql\db.MAI.broken

copy /Y C:\xampp\mysql\backup\mysql\db.frm C:\xampp\mysql\data\mysql\db.frm
copy /Y C:\xampp\mysql\backup\mysql\db.MAD C:\xampp\mysql\data\mysql\db.MAD
copy /Y C:\xampp\mysql\backup\mysql\db.MAI C:\xampp\mysql\data\mysql\db.MAI
```

If you see:

```text
The innodb_system data file 'ibdata1' must be writable
```

check for locked processes and read-only attributes:

```bat
taskkill /F /IM mysqld.exe
attrib -R C:\xampp\mysql\data\ibdata1
```
