EXEC sp_MSforeachdb 'USE [?]; 
SELECT OBJECT_NAME(i.object_id) AS TableName, i.name AS index_name, COL_NAME(ic.object_id, ic.column_id) AS column_name, ''ALTER INDEX ['' + i.NAME + ''] ON ['' + OBJECT_NAME(i.object_id) + ''] REBUILD WITH (SORT_IN_TEMPDB = OFF, ONLINE = ON, FILLFACTOR = 100)'' AS RebuildSQL
	FROM sys.indexes AS i
	INNER JOIN sys.index_columns AS ic ON i.object_id = ic.object_id
										  AND i.index_id = ic.index_id
	INNER JOIN sys.columns AS c ON c.object_id = ic.object_id
								   AND c.column_id = ic.column_id
	WHERE i.fill_factor != 0
		AND c.is_identity = 1;
'
