SELECT DB_NAME(mf.database_id) AS databaseName,
       name AS File_LogicalName,
       CASE
           WHEN type_desc = 'LOG' THEN
               'Log File'
           WHEN type_desc = 'ROWS' THEN
               'Data File'
           ELSE
               type_desc
       END AS File_type_desc,
       mf.physical_name,
       num_of_reads,
       num_of_bytes_read,
       io_stall_read_ms,
       num_of_writes,
       num_of_bytes_written,
       io_stall_write_ms,
       io_stall,
       size_on_disk_bytes,
       size_on_disk_bytes / 1024 AS size_on_disk_KB,
       size_on_disk_bytes / 1024 / 1024 AS size_on_disk_MB,
       size_on_disk_bytes / 1024 / 1024 / 1024 AS size_on_disk_GB
FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS divfs
    JOIN sys.master_files AS mf
        ON mf.database_id = divfs.database_id
           AND mf.file_id = divfs.file_id
WHERE physical_name LIKE '<Value>'
ORDER BY num_of_reads DESC;
