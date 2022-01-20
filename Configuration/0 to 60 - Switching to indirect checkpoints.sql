-- 0 to 60 - Switching to indirect checkpoints
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script changes the TARGET_RECOVERY_TIME for every user database on the instance from 0 to 60, in order to trigger indirect checkpoints
-- Modified from https://sqlperformance.com/2020/05/system-configuration/0-to-60-switching-to-indirect-checkpoints

DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += N'ALTER DATABASE ' + QUOTENAME(name) + N' SET TARGET_RECOVERY_TIME = 60 SECONDS;'
FROM sys.databases AS d
WHERE target_recovery_time_in_seconds = 0
      AND name NOT IN ( 'master', 'msdb', 'tempdb' )
      AND [state] = 0
      AND is_read_only = 0
      AND NOT EXISTS
(
    SELECT 1
    FROM sys.dm_hadr_availability_replica_states AS s
        INNER JOIN sys.availability_databases_cluster AS c
            ON s.group_id = c.group_id
    WHERE c.database_name = d.name
          AND
          (
              s.role_desc = 'SECONDARY'
              AND s.is_local = 1
          )
);

SELECT DatabaseCount = @@ROWCOUNT,
       Version = @@VERSION,
       cmd = @sql;

EXEC sys.sp_executesql @sql = @sql;