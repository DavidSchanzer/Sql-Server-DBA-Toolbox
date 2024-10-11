-- Find indexes that aren't compressed in all databases
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists all indexes that have the DATA_COMPRESSION property set to NULL

IF OBJECT_ID('TempDB..#Temp', 'U') > 0
    DROP TABLE #Temp;

CREATE TABLE #Temp
(
    DatabaseName sysname NULL,
    SchemaName sysname NULL,
    TableName sysname NULL,
    IndexName sysname NULL,
    IndexType NVARCHAR(60) NULL,
    PartitionNumber TINYINT NULL,
    CurrentCompression NVARCHAR(60) NULL,
    TotalRows BIGINT NULL
);

INSERT INTO #Temp
(
    DatabaseName,
    SchemaName,
    TableName,
    IndexName,
    IndexType,
    PartitionNumber,
    CurrentCompression,
    TotalRows
)
EXEC master.dbo.sp_ineachdb @command = '
SELECT ''?'' AS DatabaseName,
    	SCHEMA_NAME(t.schema_id) AS SchemaName,
        t.name AS TableName,
        i.name AS IndexName,
        i.type_desc AS IndexType,
        p.partition_number AS PartitionNumber,
        p.data_compression_desc AS CurrentCompression,
        p.rows AS TotalRows
FROM sys.tables AS t
    INNER JOIN sys.indexes AS i
        ON t.object_id = i.object_id
    INNER JOIN sys.partitions AS p
        ON i.object_id = p.object_id
            AND i.index_id = p.index_id
WHERE i.index_id > 0
        AND t.is_ms_shipped = 0
        AND t.type = N''U''
        AND p.data_compression_desc = ''NONE''
    	AND NOT EXISTS
    	( SELECT * FROM sys.columns AS c
			INNER JOIN sys.types AS tp ON tp.system_type_id = c.system_type_id
			WHERE c.object_id = t.object_id AND
			(
				( c.is_sparse = 1 OR c.is_column_set = 1 )	-- table has a column that is sparse or a column set
				OR 
				(
					(tp.name in (''VARCHAR'', ''NVARCHAR'') and c.max_length = -1)	-- table has a (n)varchar(max) column
					OR tp.name in (''TEXT'', ''NTEXT'', ''IMAGE'', ''VARBINARY'', ''XML'', ''FILESTREAM'')		-- table has a column that is one of these data types
				)
			)
		)
', @user_only = 1;

SELECT DatabaseName,
       SchemaName,
       TableName,
       IndexName,
       IndexType,
       PartitionNumber,
       CurrentCompression,
       TotalRows
FROM #Temp
WHERE DatabaseName NOT IN ( '[master]', '[model]', '[msdb]', '[tempdb]' )
      AND NOT (
                  CAST(SERVERPROPERTY('Edition') AS VARCHAR(100)) LIKE 'Standard Edition%'
                  AND SERVERPROPERTY('ProductMajorVersion') = '12'
              ) -- Not SQL Server 2014 Standard Edition, because this didn't support data compression
ORDER BY DatabaseName,
         SchemaName,
         TableName,
         IndexName;

DROP TABLE #Temp;
