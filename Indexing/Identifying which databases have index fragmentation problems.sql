-- Identifying which databases have index fragmentation problems
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists indexes in user databases that have more than 100 pages and a fragmentation level of 5% or above

SELECT db.database_id,
       ps.object_id,
       SI.index_id,
       db.name AS databaseName,
       OBJECT_NAME(ps.object_id, db.database_id) AS objectName,
       SI.name AS indexName,
       ps.partition_number AS partitionNumber,
       ps.avg_fragmentation_in_percent AS fragmentation,
       ps.page_count
FROM sys.databases db
    INNER JOIN sys.dm_db_index_physical_stats(NULL, NULL, NULL, NULL, N'Limited') ps
        ON db.database_id = ps.database_id
    LEFT OUTER JOIN sys.indexes AS SI
        ON ps.object_id = SI.object_id
           AND ps.index_id = SI.index_id
WHERE ps.index_id > 0
      AND ps.page_count > 100
      AND ps.avg_fragmentation_in_percent > 5
      AND db.database_id > 4 -- exclude system databases
      AND OBJECT_NAME(ps.object_id, db.database_id) <> 'distribution' -- exclude the system 'distribution' database
ORDER BY ps.avg_fragmentation_in_percent DESC
OPTION (MAXDOP 1);
