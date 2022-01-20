-- Generate RESTORE script for all user databases
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script queries the msdb database on the current instance to return the RESTORE DATABASE and RESTORE LOG statements
-- to recover databases to the latest backup. Note that Differential backups are not included.

EXEC dbo.sp_ineachdb @command = '
DECLARE @databaseName sysname;
DECLARE @backup_set_id_start INT;
DECLARE @backup_set_id_end INT;

-- set database to be used 
SET @databaseName = DB_NAME();

SELECT @backup_set_id_start = MAX(backup_set_id)
FROM msdb.dbo.backupset
WHERE database_name = @databaseName
      AND type = ''D'';

SELECT @backup_set_id_end = MIN(backup_set_id)
FROM msdb.dbo.backupset
WHERE database_name = @databaseName
      AND type = ''D''
      AND backup_set_id > @backup_set_id_start;

IF @backup_set_id_end IS NULL
    SET @backup_set_id_end = 999999999;

SELECT DB_NAME(),
       b.backup_set_id,
       ''RESTORE DATABASE '' + @databaseName + '' FROM DISK = '''''' + mf.physical_device_name + '''''' WITH NORECOVERY''
FROM msdb.dbo.backupset AS b
    INNER JOIN msdb.dbo.backupmediafamily AS mf
        ON b.media_set_id = mf.media_set_id
WHERE b.database_name = @databaseName
      AND b.backup_set_id = @backup_set_id_start
UNION ALL
SELECT DB_NAME(),
       b.backup_set_id,
       ''RESTORE LOG '' + @databaseName + '' FROM DISK = '''''' + mf.physical_device_name + '''''' WITH NORECOVERY''
FROM msdb.dbo.backupset AS b
    INNER JOIN msdb.dbo.backupmediafamily AS mf
        ON b.media_set_id = mf.media_set_id
WHERE b.database_name = @databaseName
      AND b.backup_set_id >= @backup_set_id_start
      AND b.backup_set_id < @backup_set_id_end
      AND b.type = ''L''
UNION
SELECT DB_NAME(),
       999999999 AS backup_set_id,
       ''RESTORE DATABASE '' + @databaseName + '' WITH RECOVERY''
ORDER BY b.backup_set_id;
',
                     @user_only = 1;
