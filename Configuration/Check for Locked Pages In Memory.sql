-- Check for Locked Pages In Memory
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script reveals the current status of Lock Pages in Memory for the instance

SELECT CASE sql_memory_model_desc
           WHEN 'CONVENTIONAL' THEN
               'LPIM not enabled'
           WHEN 'LOCK_PAGES' THEN
               'LPIM enabled'
           ELSE
               sql_memory_model_desc
       END
FROM sys.dm_os_sys_info;
