-- Tracking page compression success rates
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script shows the success rate of page compression for indexes, down to the partition level
-- From https://www.sqlskills.com/blogs/paul/the-curious-case-of-tracking-page-compression-success-rates/

SELECT DISTINCT
       OBJECT_NAME(i.object_id) AS [Table],
       i.name AS [Index],
       p.partition_number AS [Partition],
       ios.page_compression_attempt_count,
       ios.page_compression_success_count,
       ios.page_compression_success_count * 1.0 / ios.page_compression_attempt_count AS [SuccessRate]
FROM sys.indexes AS i
    INNER JOIN sys.partitions AS p
        ON p.object_id = i.object_id
    CROSS APPLY sys.dm_db_index_operational_stats(DB_ID(), i.object_id, i.index_id, p.partition_number) AS ios
WHERE p.data_compression = 2
      AND ios.page_compression_attempt_count > 0
ORDER BY [SuccessRate];
