-- Calculate rows inserted per second for all tables
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script gets a count of rows in all tables in this database, waits for 30 secs, then compares and calculates rows inserted per second.
-- Values to be modified before execution:
DECLARE @newBaseline BIT = 1,        -- change to 0 when you don't want to replace the baseline, i.e. after initial run
        @delay CHAR(8) = '00:00:30'; -- change as needed

IF @newBaseline = 1
BEGIN
    IF OBJECT_ID('tempdb..#baseline') IS NOT NULL
        DROP TABLE #baseline;

    CREATE TABLE #baseline
    (
        database_name sysname NULL,
        table_name sysname NULL,
        table_rows BIGINT NULL,
        captureTime DATETIME NULL
    );
END;

IF OBJECT_ID('tempdb..#current') IS NOT NULL
    DROP TABLE #current;

CREATE TABLE #current
(
    database_name sysname NULL,
    table_name sysname NULL,
    table_rows BIGINT NULL,
    captureTime DATETIME NULL
);

IF @newBaseline = 1
BEGIN
    EXECUTE dbo.sp_ineachdb @command = '
        INSERT INTO #baseline
        SELECT DB_NAME()
            , o.name As [tableName]
            , SUM(p.[rows]) As [rowCnt]
            , GETDATE() As [captureTime]
        FROM sys.indexes As i
        JOIN sys.partitions As p
            ON i.[object_id] = p.[object_id]
           AND i.index_id  = p.index_id
        JOIN sys.objects As o
            ON i.[object_id] = o.[object_id]
        WHERE i.[type] = 1
        GROUP BY o.name;';

    WAITFOR DELAY @delay;
END;

EXECUTE dbo.sp_ineachdb @command = '
INSERT INTO #current
SELECT DB_NAME()
    , o.name As [tableName]
    , SUM(p.[rows]) As [rowCnt]
    , GETDATE() As [captureTime]
FROM sys.indexes As i
JOIN sys.partitions As p
    ON i.[object_id] = p.[object_id]
   AND i.index_id  = p.index_id
JOIN sys.objects As o
    ON i.[object_id] = o.[object_id]
WHERE i.[type] = 1
GROUP BY o.name;';

SELECT c.database_name,
       c.table_name,
       c.table_rows,
       c.captureTime,
       c.table_rows - b.table_rows AS new_rows,
       DATEDIFF(SECOND, b.captureTime, c.captureTime) AS time_diff,
       (c.table_rows - b.table_rows) / DATEDIFF(SECOND, b.captureTime, c.captureTime) AS rows_per_sec
FROM #baseline AS b
    JOIN #current AS c
        ON b.table_name = c.table_name
           AND b.database_name = c.database_name
ORDER BY new_rows DESC;
