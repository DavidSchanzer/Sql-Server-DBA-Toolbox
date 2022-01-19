-- Individual index fragmentation
-- select DB_NAME(database_id), OBJECT_NAME(DMV.object_id, database_id), SI.name AS index_name, avg_fragmentation_in_percent,
--		  'ALTER INDEX ' + SI.name + ' ON dbo.' + OBJECT_NAME(DMV.object_id, database_id) + ' REBUILD WITH (ONLINE = ON)'
--     from sys.dm_db_index_physical_stats (<database_id>,<object_id>,<index_id>,null,'Limited') AS DMV
--     LEFT OUTER JOIN sys.indexes AS SI
--             ON DMV.object_id = SI.object_id
--            AND DMV.index_id = SI.index_id

SELECT
      db.database_id, ps.object_id, SI.index_id,
      db.name AS databaseName
    , OBJECT_NAME(ps.object_id, db.database_id) AS objectName
    , SI.name AS indexName
    , ps.partition_number AS partitionNumber
    , ps.avg_fragmentation_in_percent AS fragmentation
    , ps.page_count
FROM sys.databases db
INNER JOIN sys.dm_db_index_physical_stats (NULL, NULL, NULL , NULL, N'Limited') ps
	ON db.database_id = ps.database_id
LEFT OUTER JOIN sys.indexes AS SI
	ON ps.object_id = SI.object_id
	AND ps.index_id = SI.index_id
WHERE ps.index_id > 0 
   AND ps.page_count > 100 
   AND ps.avg_fragmentation_in_percent > 5
   AND db.database_id > 4 -- exclude system databases
   AND OBJECT_NAME(ps.object_id, db.database_id) != 'distribution' -- exclude the system 'distribution' database
order by ps.avg_fragmentation_in_percent desc
OPTION (MaxDop 1)
