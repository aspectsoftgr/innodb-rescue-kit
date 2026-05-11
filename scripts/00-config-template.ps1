# Copy and adapt these values for your environment.
$RecoveryConfig = @{
  MysqlExe      = "C:\xampp\mysql\bin\mysql.exe"
  MysqlDumpExe  = "C:\xampp\mysql\bin\mysqldump.exe"
  MysqlCheckExe = "C:\xampp\mysql\bin\mysqlcheck.exe"
  PythonExe     = "C:\Python3\python.exe"
  DbsakePath    = "C:\tools\dbsake"
  DbsakeWrapper = "C:\tools\dbsake_blobfix_runner.py"
  MysqlUser     = "root"
  MysqlPassword = "root"
  ActiveDataDir = "C:\xampp\mysql\data"
  OldDataDir    = "C:\xampp\mysql\data_orphaned_for_recovery"
}
