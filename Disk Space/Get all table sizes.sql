-- Get all table sizes
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists all tables in user databases, with create and last modified dates, and table and index size information 

DROP TABLE IF EXISTS #TableSizes;
CREATE TABLE #TableSizes
(
    DatabaseName sysname NOT NULL,
    SchemaName sysname NOT NULL,
    TableName sysname NOT NULL,
    CreatedDate CHAR(8) NOT NULL,
    LastModifiedDate CHAR(8) NOT NULL,
    DataSizeInKB BIGINT NOT NULL,
    IndexSizeInKB BIGINT NOT NULL,
    [DataSizeInKB + IndexSizeInKB] VARCHAR(100) NOT NULL
);

INSERT INTO #TableSizes
EXEC sp_ineachdb @command = '
		WITH cte
		AS (SELECT DB_NAME() AS DatabaseName,
				   SCHEMA_NAME(t.schema_id) AS SchemaName,
				   t.name AS TableName,
				   CONVERT(VARCHAR, create_date, 112) AS CreatedDate,
				   CONVERT(VARCHAR, modify_date, 112) AS LastModifiedDate,
				   SUM(s.used_page_count) AS used_pages_count,
				   SUM(   CASE
							  WHEN (i.index_id < 2) THEN
						  (s.in_row_data_page_count + s.lob_used_page_count + s.row_overflow_used_page_count)
							  ELSE
								  s.lob_used_page_count + s.row_overflow_used_page_count
						  END
					  ) AS pages
			FROM sys.dm_db_partition_stats AS s
				JOIN sys.tables AS t
					ON s.object_id = t.object_id
				JOIN sys.indexes AS i
					ON i.[object_id] = t.[object_id]
					   AND s.index_id = i.index_id
			GROUP BY SCHEMA_NAME(t.schema_id),
					 t.name,
					 CONVERT(VARCHAR, create_date, 112),
					 CONVERT(VARCHAR, modify_date, 112)),
			 cte2
		AS (SELECT cte.DatabaseName,
				   cte.SchemaName,
				   cte.TableName,
				   cte.CreatedDate,
				   cte.LastModifiedDate,
				   (cte.pages * 8.) AS DataSizeInKB,
				   ((CASE
						 WHEN cte.used_pages_count > cte.pages THEN
							 cte.used_pages_count - cte.pages
						 ELSE
							 0
					 END
					) * 8.
				   ) AS IndexSizeInKB
			FROM cte)
		SELECT cte2.DatabaseName,
			   cte2.SchemaName,
			   cte2.TableName,
			   cte2.CreatedDate,
			   cte2.LastModifiedDate,
			   cte2.DataSizeInKB,
			   cte2.IndexSizeInKB,
			   CASE
				   WHEN t.s > 1024 * 1024 THEN
					   FORMAT(t.s / 1024 / 1024, ''0.###'''' GB'''''')
				   WHEN t.s > 1024 THEN
					   FORMAT(t.s / 1024, ''0.###'''' MB'''''')
				   ELSE
					   FORMAT(t.s, ''0.###'''' KB'''''')
			   END AS [TableSize + IndexSize]
		FROM cte2
			CROSS APPLY
		(
			VALUES
				(cte2.DataSizeInKB + cte2.IndexSizeInKB)
		) t (s);
	',
                 @user_only = 1, @exclude_list = 'SSISDB';

SELECT DatabaseName,
       SchemaName,
       TableName,
       CreatedDate,
       LastModifiedDate,
       DataSizeInKB,
       IndexSizeInKB,
       [DataSizeInKB + IndexSizeInKB]
FROM #TableSizes
ORDER BY DatabaseName,
         SchemaName,
         TableName;
