-- Turn all Heaps into Clustered Columnstore with Archive Compression
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script transforms each Heap table (table without a clustered index) into a clustered columnstore table with Archive compression.
-- This is useful for reducing a database that has many Heap (eg. archiving or logging) tables to be as small as possible.

DECLARE @SchemaName	SYSNAME,
		@TableName	SYSNAME,
		@SQL		VARCHAR(255);

DECLARE heap_cur CURSOR LOCAL FAST_FORWARD FOR
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
