-- Find unused indexes from sys.dm_db_index_usage_stats
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script can help identify indexes that have not been used since the last instance restart. You can also switch the sort
-- order to see your heavily used indexes.
--
-- The "reads_per_write" field helps to find indexes that aren't helping to improve performance. For every 1 write
-- to the index, you want to see as many reads as possible. Indexes with a reads_per_write score of 1 mean that for
-- every 1 write, the index is also used 1 time to help with performance. Ideally, you want to see scores much
-- higher than that. Consider dropping indexes with a reads_per_write score under 1, and strongly consider
-- dropping ones with scores under .1. 
--
-- This isn't a hard-and-fast rule: for example, you may have an index that's only used once per month for a single
-- report, but that report is run by the CEO and he wants it instantaneously. Before dropping indexes, know what
-- they're used for, or make sure alternate indexes exist. Alternate indexes would be indexes that are wider than
-- the index you're dropping, and include enough fields to serve the query's needs.

CREATE TABLE #output
(
    DatabaseName sysname NOT NULL,
    TableName sysname NOT NULL,
    IndexName sysname NOT NULL,
    Rows BIGINT NOT NULL,
    Reads BIGINT NOT NULL,
    Writes BIGINT NOT NULL,
    ReadsPerWrite DECIMAL(18, 1) NOT NULL,
    DropStatement VARCHAR(255) NOT NULL
);
INSERT INTO #output
(
    DatabaseName,
    TableName,
    IndexName,
    Rows,
    Reads,
    Writes,
    ReadsPerWrite,
    DropStatement
)
EXEC dbo.sp_ineachdb @command = 'SELECT DB_NAME() AS DatabaseName,
       o.name AS TableName,
       i.name AS IndexName,
       (
           SELECT SUM(p.rows)
           FROM sys.partitions p
           WHERE p.index_id = i.index_id
                 AND i.object_id = p.object_id
       ) AS Rows,
       s.user_seeks + s.user_scans + s.user_lookups AS Reads,
       s.user_updates AS Writes,
       CASE
           WHEN s.user_updates < 1 THEN
               0
           ELSE
               1.00 * (s.user_seeks + s.user_scans + s.user_lookups) / s.user_updates
       END AS ReadsPerWrite,
       ''DROP INDEX '' + QUOTENAME(i.name) + '' ON '' + QUOTENAME(c.name) + ''.'' + QUOTENAME(OBJECT_NAME(i.object_id)) + '';'' AS ''DropStatement''
FROM sys.indexes i
    INNER JOIN sys.objects o
        ON i.object_id = o.object_id
    INNER JOIN sys.schemas c
        ON o.schema_id = c.schema_id
    LEFT OUTER JOIN sys.dm_db_index_usage_stats s
        ON i.index_id = s.index_id
           AND s.object_id = i.object_id
		   AND s.database_id = DB_ID()
WHERE (
          OBJECTPROPERTY(o.object_id, ''isusertable'') = 1
          OR OBJECTPROPERTY(o.object_id, ''isview'') = 1
      )
      AND i.type_desc = ''nonclustered''
      AND i.is_primary_key = 0
      AND i.is_unique = 0
      AND i.is_unique_constraint = 0;';

SELECT DatabaseName,
       TableName,
       IndexName,
       Rows,
       Reads,
       Writes,
       ReadsPerWrite,
       DropStatement
FROM #output
WHERE (
          ReadsPerWrite = 0
          OR ReadsPerWrite IS NULL
      )
      AND Rows > 1000
      AND DatabaseName NOT IN ( 'msdb' )
ORDER BY DatabaseName,
         TableName,
         IndexName;

DROP TABLE #output;
