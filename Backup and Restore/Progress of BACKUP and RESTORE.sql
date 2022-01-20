-- Progress of BACKUP and RESTORE
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script displays information on the progress of currently running BACKUP and RESTORE commands

SELECT der.percent_complete,
       der.start_time,
       DATEADD(n, (der.estimated_completion_time / 60 / 1000), GETDATE()) AS estimated_completion_time,
       der.command,
       dest.text
FROM sys.dm_exec_requests AS der
    CROSS APPLY sys.dm_exec_sql_text(der.sql_handle) AS dest
WHERE der.command LIKE '%BACKUP%'
      OR der.command LIKE '%RESTORE%';
