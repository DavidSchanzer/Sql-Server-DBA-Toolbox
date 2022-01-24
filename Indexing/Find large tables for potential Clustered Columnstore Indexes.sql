-- Find large tables for potential Clustered Columnstore Indexes
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists tables that have at least 1 million rows that currently don't have a Clustered Columnstore index, as a candidate for such.

WITH BigTables
AS (SELECT SCHEMA_NAME(Tables.schema_id) AS [SchemaName],
           Tables.name AS [TableName],
           SUM(Partitions.rows) AS [TotalRowCount]
    FROM sys.tables AS [Tables]
        JOIN sys.partitions AS [Partitions]
            ON [Tables].[object_id] = [Partitions].[object_id]
               AND Partitions.index_id IN ( 0, 1 )
    GROUP BY SCHEMA_NAME(Tables.schema_id),
             Tables.name
    HAVING SUM(Partitions.rows) > 1000000)
SELECT b.SchemaName,
       b.TableName,
       b.TotalRowCount
FROM BigTables AS b
WHERE NOT EXISTS
(
    SELECT *
    FROM sys.indexes AS i
    WHERE i.object_id = OBJECT_ID(b.SchemaName + '.' + b.TableName)
          AND i.type_desc = 'CLUSTERED COLUMNSTORE'
)
ORDER BY b.TableName;
