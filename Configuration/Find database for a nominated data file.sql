-- Find database for a nominated data file
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script will give the database name and other details based on a specific physical file name.
-- This is useful in the circumstance where the name of the physical file doesn't match the database name.
-- Replace <Value> with the full pathname to the physical file.

SELECT DB_NAME(mf.database_id) AS databaseName,
       mf.name AS File_LogicalName,
       CASE
           WHEN mf.type_desc = 'LOG' THEN
               'Log File'
           WHEN mf.type_desc = 'ROWS' THEN
               'Data File'
           ELSE
               mf.type_desc
       END AS File_type_desc,
       mf.physical_name,
       divfs.num_of_reads,
       divfs.num_of_bytes_read,
       divfs.io_stall_read_ms,
       divfs.num_of_writes,
       divfs.num_of_bytes_written,
       divfs.io_stall_write_ms,
       divfs.io_stall,
       divfs.size_on_disk_bytes,
       divfs.size_on_disk_bytes / 1024 AS size_on_disk_KB,
       divfs.size_on_disk_bytes / 1024 / 1024 AS size_on_disk_MB,
       divfs.size_on_disk_bytes / 1024 / 1024 / 1024 AS size_on_disk_GB
FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS divfs
    JOIN sys.master_files AS mf
        ON mf.database_id = divfs.database_id
           AND mf.file_id = divfs.file_id
WHERE mf.physical_name LIKE '<Value>'
ORDER BY divfs.num_of_reads DESC;
