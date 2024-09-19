-- Find tables without a primary key or clustered index
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script returns a list of tables in user databases that either don't have a primary key or don't have a clustered index, with row counts.

CREATE TABLE #Results
(
    DatabaseName sysname NOT NULL,
    SchemaName sysname NOT NULL,
    TableName sysname NOT NULL,
    HasPrimaryKey BIT NOT NULL,
    HasClusteredIndex BIT NOT NULL,
	[RowCount] BIGINT NOT NULL
);

INSERT INTO #Results
EXEC dbo.sp_ineachdb @command = '
	SELECT ''?'',
       SCHEMA_NAME(schema_id) AS SchemaName,
       TBL.name AS TableName,
       OBJECTPROPERTY(TBL.object_id, ''TableHasPrimaryKey'') AS HasPrimaryKey,
       OBJECTPROPERTY(TBL.object_id, ''TableHasClustIndex'') AS HasClusteredIndex,
       SUM(PART.rows) AS [RowCount]
FROM sys.tables TBL
    INNER JOIN sys.partitions PART
        ON TBL.object_id = PART.object_id
    INNER JOIN sys.indexes IDX
        ON PART.object_id = IDX.object_id
           AND PART.index_id = IDX.index_id
WHERE (
          OBJECTPROPERTY(TBL.object_id, ''TableHasPrimaryKey'') = 0
          OR OBJECTPROPERTY(TBL.object_id, ''TableHasClustIndex'') = 0
      )
      AND IDX.index_id < 2
GROUP BY SCHEMA_NAME(schema_id),
         TBL.name,
         OBJECTPROPERTY(TBL.object_id, ''TableHasPrimaryKey''),
         OBJECTPROPERTY(TBL.object_id, ''TableHasClustIndex'');

	',
                     @user_only = 1;

SELECT DatabaseName,
       SchemaName,
       TableName,
       HasPrimaryKey,
       HasClusteredIndex,
	   [RowCount]
FROM #Results
ORDER BY [RowCount] DESC;

DROP TABLE IF EXISTS #Results;
