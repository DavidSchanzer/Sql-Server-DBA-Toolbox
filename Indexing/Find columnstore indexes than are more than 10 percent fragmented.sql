DECLARE @Output TABLE (DatabaseName sysname, SchemaName sysname, TableName sysname, IndexName sysname, IndexType sysname, AvgFragPct DECIMAL(4,1));

INSERT INTO @Output EXEC sp_ineachdb '
SELECT DB_NAME(), OBJECT_SCHEMA_NAME(i.object_id) AS schema_name,
       OBJECT_NAME(i.object_id) AS object_name,
       i.name AS index_name,
       i.type_desc AS index_type,
       100.0 * (ISNULL(SUM(rgs.deleted_rows), 0)) / NULLIF(SUM(rgs.total_rows), 0) AS avg_fragmentation_in_percent
FROM sys.indexes AS i
INNER JOIN sys.dm_db_column_store_row_group_physical_stats AS rgs
ON i.object_id = rgs.object_id
   AND
   i.index_id = rgs.index_id
WHERE rgs.state_desc = ''COMPRESSED''
GROUP BY i.object_id, i.index_id, i.name, i.type_desc
HAVING 100.0 * (ISNULL(SUM(rgs.deleted_rows), 0)) / NULLIF(SUM(rgs.total_rows), 0) > 10
ORDER BY schema_name, object_name, index_name, index_type;
', @user_only = 1;

SELECT *   
FROM @Output 
ORDER BY DatabaseName, SchemaName, TableName, IndexName;
