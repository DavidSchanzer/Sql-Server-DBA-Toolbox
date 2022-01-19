DECLARE @SchemaName	SYSNAME,
		@TableName	SYSNAME,
		@SQL		VARCHAR(255);

DECLARE heap_cur CURSOR FOR
	SELECT SCH.name AS SchemaName, TBL.name AS TableName 
	FROM sys.tables AS TBL 
		 INNER JOIN sys.schemas AS SCH 
			 ON TBL.schema_id = SCH.schema_id 
		 INNER JOIN sys.indexes AS IDX 
			 ON TBL.object_id = IDX.object_id 
				AND IDX.type = 0 -- = Heap 
	ORDER BY SchemaName, TableName
	FOR READ ONLY;

OPEN heap_cur;

FETCH heap_cur INTO @SchemaName, @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SQL = 'CREATE CLUSTERED COLUMNSTORE INDEX [CCI_' + @TableName + '] ON [' + @SchemaName + '].[' + @TableName + '];'
	PRINT @SQL;
	EXEC (@SQL);

	SET @SQL = 'ALTER INDEX [CCI_' + @TableName + '] ON [' + @SchemaName + '].[' + @TableName + '] REBUILD WITH (DATA_COMPRESSION = COLUMNSTORE_ARCHIVE);'
	PRINT @SQL;
	EXEC (@SQL);

	FETCH heap_cur INTO @SchemaName, @TableName;
END

CLOSE heap_cur;
DEALLOCATE heap_cur;
GO
