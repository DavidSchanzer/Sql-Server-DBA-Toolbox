-- Find unused non-clustered indices by checking Query Store and sys.dm_db_index_usage_stats
-- Note that THIS IS FOR THE CURRENT DATABASE ONLY.
--
-- List all non-clustered indexes, along with their DISABLE and DROP statements, that exist in the current database but aren't found in either the Query Store or sys.dm_db_index_usage_stats
-- (which lists index usage since last instance restart).
--
-- If an index is not listed in either place, AND
--		the plans in the Query Store are at least 1 month old (value calculated below), AND
--		the instance hasn't been restarted for at least 1 week (value calculated below),
-- then we can be reasonably confident that an index can be initially disabled, and then later deleted.
--
DROP TABLE IF EXISTS #IndicesInQueryPlans;

WITH XMLNAMESPACES
     (
         DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
     )
SELECT DISTINCT
       obj.value('(@Database)[1]', 'varchar(128)') AS DatabaseName,
       obj.value('(@Schema)[1]', 'varchar(128)') AS SchemaName,
       obj.value('(@Table)[1]', 'varchar(128)') AS TableName,
       obj.value('(@Index)[1]', 'varchar(128)') AS IndexName,
       obj.value('(@IndexKind)[1]', 'varchar(128)') AS IndexKind
INTO #IndicesInQueryPlans
FROM
(
    SELECT tp.query_plan
    FROM
    (
        SELECT TRY_CONVERT(XML, qsp.query_plan) AS query_plan
        FROM sys.query_store_plan AS qsp
    ) AS tp
) AS tab(query_plan)
    CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS batch(stmt)
    CROSS APPLY stmt.nodes('.//IndexScan/Object') AS idx(obj)
OPTION (MAXDOP 2, RECOMPILE);

DELETE FROM #IndicesInQueryPlans
WHERE IndexKind <> 'NonClustered'
      OR DatabaseName <> QUOTENAME(DB_NAME())
      OR SchemaName = '[sys]'

SELECT CAST(MIN(last_execution_time) AS DATE) AS DateOfEarliestLastExecutionForPlansInQueryStore
FROM sys.query_store_plan;

SELECT QUOTENAME(DB_NAME()) AS DatabaseName,
       QUOTENAME(c.name) AS SchemaName,
       QUOTENAME(o.name) AS TableName,
       QUOTENAME(i.name) AS IndexName,
       s.user_seeks + s.user_scans + s.user_lookups AS ReadsSinceRestart,
       s.user_updates AS WritesSinceRestart,
       (
           SELECT SUM(p.rows)
           FROM sys.partitions p
           WHERE p.index_id = i.index_id
                 AND i.object_id = p.object_id
       ) AS [RowCount],
       'ALTER INDEX ' + QUOTENAME(i.name) + ' ON ' + QUOTENAME(c.name) + '.' + QUOTENAME(OBJECT_NAME(i.object_id)) + ' DISABLE;' AS DisableStatement,
       'DROP INDEX ' + QUOTENAME(i.name) + ' ON ' + QUOTENAME(c.name) + '.' + QUOTENAME(OBJECT_NAME(i.object_id)) + ';' AS DropStatement
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
          OBJECTPROPERTY(o.object_id, 'isusertable') = 1
          OR OBJECTPROPERTY(o.object_id, 'isview') = 1
      )
      AND i.type_desc = 'nonclustered'
      AND i.is_primary_key = 0
      AND i.is_unique = 0
      AND i.is_unique_constraint = 0
      AND ( s.user_seeks + s.user_scans + s.user_lookups = 0 /* No reads on this index */ OR s.user_seeks + s.user_scans + s.user_lookups IS NULL /* Index not listed in sys.dm_db_index_usage_stats */)
      AND NOT EXISTS
(
    SELECT *
    FROM #IndicesInQueryPlans AS IIQP
    WHERE IIQP.DatabaseName = QUOTENAME(DB_NAME(s.database_id)) COLLATE DATABASE_DEFAULT
          AND IIQP.SchemaName = QUOTENAME(c.name) COLLATE DATABASE_DEFAULT
          AND IIQP.TableName = QUOTENAME(o.name) COLLATE DATABASE_DEFAULT
          AND IIQP.IndexName = QUOTENAME(i.name) COLLATE DATABASE_DEFAULT
)
ORDER BY DatabaseName,
         SchemaName,
         TableName,
         IndexName;
