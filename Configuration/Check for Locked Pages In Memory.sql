SELECT CASE sql_memory_model_desc
           WHEN 'CONVENTIONAL' THEN
               'LPIM not enabled'
           WHEN 'LOCK_PAGES' THEN
               'LPIM enabled'
           ELSE
               sql_memory_model_desc
       END
FROM sys.dm_os_sys_info;
