-- Get backup file names to restore a nominated database and point in time
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists the database backup file names that will be needed to restore the nominated database to the nominated point in time.

DECLARE @DatabaseName sysname = '<DatabaseName>',
        @TargetRecoveryTime DATETIME = '<TargetRecoveryTime>',
        @DiffCheckpointLSN NUMERIC(25),
        @FullCheckpointLSN NUMERIC(25);

SELECT 'Backups to restore database ' + @DatabaseName + ' as close as possible to '
       + CONVERT(CHAR(26), @TargetRecoveryTime, 113);

-- Get the checkpoint_lsn of the Full backup.
SELECT @FullCheckpointLSN = MAX(checkpoint_lsn)
FROM msdb.dbo.backupset
WHERE database_name = @DatabaseName
      AND type = 'D'
      AND backup_start_date < @TargetRecoveryTime;

-- Get the checkpoint_lsn of the Differential backup, which is the most recent one (before the target recovery time) whose database_backup_lsn matches the Full backup's checkpoint_lsn.
SELECT @DiffCheckpointLSN = COALESCE(MAX(checkpoint_lsn), 0) -- If there is no such Differential backup, set to zero so that subsequent Transaction Log backups can be found
FROM msdb.dbo.backupset
WHERE database_name = @DatabaseName
      AND backup_start_date < @TargetRecoveryTime
      AND type = 'I'
      AND database_backup_lsn = @FullCheckpointLSN;

SELECT CASE
           WHEN b.type = 'D'
                AND b.is_copy_only = 0 THEN
               'Full Database'
           WHEN b.type = 'D'
                AND b.is_copy_only = 1 THEN
               'Full Copy-Only Database'
           WHEN b.type = 'I' THEN
               'Differential Database'
           WHEN b.type = 'L' THEN
               'Transaction Log'
           WHEN b.type = 'F' THEN
               'File or filegroup'
           WHEN b.type = 'G' THEN
               'Differential file'
           WHEN b.type = 'P' THEN
               'Partial'
           WHEN b.type = 'Q' THEN
               'Differential partial'
           ELSE
               NULL
       END + ' Backup' AS BackupType,
       CASE mf.device_type
           WHEN 2 THEN
               'Disk'
           WHEN 5 THEN
               'Tape'
           WHEN 7 THEN
               'Virtual device'
           WHEN 9 THEN
               'Azure Storage'
           WHEN 105 THEN
               'A permanent backup device'
           ELSE
               'Other Device'
       END AS DeviceType,
       mf.physical_device_name AS PhysicalDeviceName,
       ms.software_name AS backup_software,
       b.recovery_model,
       b.compatibility_level,
       b.backup_start_date AS BackupStartDate,
       b.backup_finish_date AS BackupFinishDate,
       CONVERT(DECIMAL(10, 2), b.backup_size / 1024. / 1024.) AS BackupSizeMB,
       CONVERT(DECIMAL(10, 2), b.compressed_backup_size / 1024. / 1024.) AS CompressedBackupSizeMB,
       ms.is_password_protected
FROM msdb.dbo.backupset AS b
    LEFT OUTER JOIN msdb.dbo.backupmediafamily AS mf
        ON b.media_set_id = mf.media_set_id
    INNER JOIN msdb.dbo.backupmediaset ms
        ON b.[media_set_id] = ms.[media_set_id]
WHERE b.database_name = @DatabaseName
      AND b.backup_start_date < @TargetRecoveryTime
      AND
      (
          (
              b.type = 'D'
              AND b.checkpoint_lsn = @FullCheckpointLSN
          ) -- Get the specific Full backup that we found
          OR
          (
              b.type = 'I'
              AND b.checkpoint_lsn = @DiffCheckpointLSN
          ) -- Get the specific Diff backup that we found
          OR
          (
              b.type = 'L'
              AND b.database_backup_lsn = @FullCheckpointLSN
              AND b.checkpoint_lsn >= @DiffCheckpointLSN
          )
      ) -- Get all subsequent Transaction Log backups (before the target recovery time) whose database_backup_lsn matches the Full backup's checkpoint_lsn.
ORDER BY b.backup_start_date;
