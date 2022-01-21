-- Find largest table in all databases
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script returns one row per user database, showing the name of the largest table and its size in MB.
-- This can be useful for looking for low-hanging fruit when trying to clear space on an instance, for instance by discovering a large logging table.

CREATE TABLE #output
(
    DBName sysname NULL,
    SchemaName sysname NULL,
    TableName sysname NULL,
    SpaceMB BIGINT NULL
);

INSERT INTO #output
(
    DBName, SchemaName,
    TableName,
    SpaceMB
)
EXEC dbo.sp_ineachdb @command = '
SELECT TOP 1 db_name() AS DatabaseName,
    s.Name AS SchemaName,
    t.NAME AS TableName,
    SUM(a.total_pages) * 8 / 1024 AS TotalSpaceMB
FROM
    sys.tables t
INNER JOIN
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN
    sys.schemas s ON t.schema_id = s.schema_id
WHERE
    t.NAME NOT LIKE ''dt%''
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255
GROUP BY
    t.Name, s.Name, p.Rows
ORDER BY
    SUM(a.total_pages) DESC 
',
                     @user_only = 1;

SELECT DBName,SchemaName,
       TableName,
       SpaceMB
FROM #output;

DROP TABLE #output;
