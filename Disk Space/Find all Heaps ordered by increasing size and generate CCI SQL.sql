-- Find all Heaps ordered by decreasing size and generate CCI SQL
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists all Heap tables (tables without a clustered index) and generates the CREATE CLUSTERED COLUMNSTORE INDEX statement.
-- This is useful to reduce the disk space required for "archive"-style databases and tables that are created using the SELECT ... INTO ... pattern.

IF OBJECT_ID('TempDB..#Temp', 'U') > 0
    DROP TABLE #Temp;

CREATE TABLE #Temp
(
    DatabaseName sysname NULL,
    SchemaName sysname NULL,
    TableName sysname NULL,
    DataSpaceMB INT NULL
);

INSERT INTO #Temp
(
    DatabaseName,
    SchemaName,
    TableName,
    DataSpaceMB
)
EXEC master.dbo.sp_ineachdb @command = '
SELECT ''?'' AS DatabaseName,
    	SCH.name AS SchemaName,
       TBL.name AS TableName,
       (SUM(AU.data_pages) * 8) / 1024 AS DataSpaceMB
FROM sys.tables AS TBL WITH (NOLOCK)
    INNER JOIN sys.schemas AS SCH WITH (NOLOCK)
        ON TBL.schema_id = SCH.schema_id
    INNER JOIN sys.indexes AS IDX WITH (NOLOCK)
        ON TBL.object_id = IDX.object_id
           AND IDX.type = 0 -- = Heap 
    INNER JOIN sys.partitions AS PAR WITH (NOLOCK)
        ON IDX.object_id = PAR.object_id
           AND IDX.index_id = PAR.index_id
    INNER JOIN sys.allocation_units AS AU WITH (NOLOCK)
        ON PAR.partition_id = AU.container_id
	WHERE NOT EXISTS
		( SELECT * FROM sys.columns AS COL WITH (NOLOCK)
			WHERE COL.object_id = TBL.object_id AND
			( COL.user_type_id IN (34, 35, 98, 99, 128, 129, 130, 189, 241)	-- image, text, sql_variant, ntext, hierarchyid, geometry, geography, timestamp, xml
			--OR COL.system_type_id IN (167, 231) AND COL.max_length = -1		-- varchar(max) and nvarchar(max)
			OR COL.is_computed = 1 ))
GROUP BY SCH.name,
         TBL.name
ORDER BY SchemaName,
         TableName;
', @user_only = 1;

SELECT DatabaseName,
       SchemaName,
       TableName,
       DataSpaceMB,
       'USE ' + DatabaseName + '; CREATE CLUSTERED COLUMNSTORE INDEX [CCI_' + TableName + '] ON [' + SchemaName
       + '].[' + TableName + '];' AS CreateClusteredColumnstoreSQL
FROM #Temp
WHERE DatabaseName NOT IN ( 'master', 'model', 'msdb', 'tempdb', 'SSISDB' )
      AND DatabaseName NOT LIKE '\[ReportServer%' ESCAPE '\'
      AND DatabaseName NOT LIKE '\[Project%' ESCAPE '\'
      AND DatabaseName NOT LIKE '\[MLK%' ESCAPE '\'
      AND DatabaseName NOT LIKE '\[Choicemaker%' ESCAPE '\'
ORDER BY DataSpaceMB DESC,
         DatabaseName,
         SchemaName,
         TableName;
DROP TABLE #Temp;
