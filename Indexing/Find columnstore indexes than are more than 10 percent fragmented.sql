-- Find columnstore indexes than are more than 10 percent fragmented
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script returns a list of columnstore indexes that have an average fragmentation percentage of 10% or higher

DECLARE @Output TABLE
(
    DatabaseName sysname NOT NULL,
    SchemaName sysname NOT NULL,
    TableName sysname NOT NULL,
    IndexName sysname NOT NULL,
    IndexType sysname NOT NULL,
    AvgFragPct DECIMAL(4, 1) NOT NULL,
	RebuildStatement VARCHAR(255)
);

INSERT INTO @Output
EXEC dbo.sp_ineachdb @command = '
SELECT DB_NAME(), OBJECT_SCHEMA_NAME(i.object_id) AS schema_name,
       OBJECT_NAME(i.object_id) AS object_name,
       i.name AS index_name,
       i.type_desc AS index_type,
       100.0 * (ISNULL(SUM(rgs.deleted_rows), 0)) / NULLIF(SUM(rgs.total_rows), 0) AS avg_fragmentation_in_percent,
	   ''USE ['' + DB_NAME() + '']; ALTER INDEX ['' + i.name + ''] ON ['' + OBJECT_SCHEMA_NAME(i.object_id) + ''].['' + OBJECT_NAME(i.object_id) + ''] REBUILD PARTITION = ALL;'' AS rebuild_statement
FROM sys.indexes AS i
INNER JOIN sys.dm_db_column_store_row_group_physical_stats AS rgs
ON i.object_id = rgs.object_id
   AND
   i.index_id = rgs.index_id
WHERE rgs.state_desc = ''COMPRESSED''
GROUP BY i.object_id, i.index_id, i.name, i.type_desc
HAVING 100.0 * (ISNULL(SUM(rgs.deleted_rows), 0)) / NULLIF(SUM(rgs.total_rows), 0) > 10
ORDER BY schema_name, object_name, index_name, index_type;
',
@user_only = 1;

SELECT DatabaseName,
       SchemaName,
       TableName,
       IndexName,
       IndexType,
       AvgFragPct,
	   RebuildStatement
FROM @Output
ORDER BY DatabaseName,
         SchemaName,
         TableName,
         IndexName;
