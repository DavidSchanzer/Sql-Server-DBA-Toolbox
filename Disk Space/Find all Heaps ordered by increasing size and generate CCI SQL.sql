-- Find all Heaps ordered by increasing size and generate CCI SQL
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
FROM sys.tables AS TBL
    INNER JOIN sys.schemas AS SCH
        ON TBL.schema_id = SCH.schema_id
    INNER JOIN sys.indexes AS IDX
        ON TBL.object_id = IDX.object_id
           AND IDX.type = 0 -- = Heap 
    INNER JOIN sys.partitions AS PAR
        ON IDX.object_id = PAR.object_id
           AND IDX.index_id = PAR.index_id
    INNER JOIN sys.allocation_units AS AU
        ON PAR.partition_id = AU.container_id
	WHERE NOT EXISTS
		( SELECT * FROM sys.columns AS COL
			WHERE COL.object_id = TBL.object_id AND
			( COL.user_type_id IN (34, 35, 98, 99, 128, 129, 130, 189, 241)	-- image, text, sql_variant, ntext, hierarchyid, geometry, geography, timestamp, xml
			OR COL.system_type_id IN (167, 231) AND COL.max_length = -1		-- varchar(max) and nvarchar(max)
			OR COL.is_computed = 1 ))
GROUP BY SCH.name,
         TBL.name
ORDER BY SchemaName,
         TableName;
';

SELECT DatabaseName,
       SchemaName,
       TableName,
       DataSpaceMB,
       'USE [' + DatabaseName + ']; CREATE CLUSTERED COLUMNSTORE INDEX [CCI_' + TableName + '] ON [' + SchemaName
       + '].[' + TableName + '];' AS CreateClusteredColumnstoreSQL
FROM #Temp
WHERE DatabaseName NOT IN ( 'master', 'model', 'msdb', 'tempdb', 'SSISDB' )
      AND DatabaseName NOT LIKE 'ReportServer%'
      AND DatabaseName NOT LIKE 'Project%'
      AND DatabaseName NOT LIKE 'MLK%'
      AND DatabaseName NOT LIKE 'Choicemaker%'
ORDER BY DataSpaceMB,
         DatabaseName,
         SchemaName,
         TableName;
DROP TABLE #Temp;
