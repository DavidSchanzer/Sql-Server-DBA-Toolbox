-- Plan Cache queries - key lookups
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists all queries in the Plan Cache that have any key lookups.

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

WITH XMLNAMESPACES
(
    DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
)
SELECT n.value('(@StatementText)[1]', 'VARCHAR(4000)') AS sql_text,
       n.query('.'),
       i.value('(@PhysicalOp)[1]', 'VARCHAR(128)') AS PhysicalOp,
       i.value('(./IndexScan/Object/@Database)[1]', 'VARCHAR(128)') AS DatabaseName,
       i.value('(./IndexScan/Object/@Schema)[1]', 'VARCHAR(128)') AS SchemaName,
       i.value('(./IndexScan/Object/@Table)[1]', 'VARCHAR(128)') AS TableName,
       i.value('(./IndexScan/Object/@Index)[1]', 'VARCHAR(128)') AS IndexName,
       i.query('.'),
       STUFF(
       (
           SELECT DISTINCT
                  ', ' + cg.value('(@Column)[1]', 'VARCHAR(128)')
           FROM i.nodes('./OutputList/ColumnReference') AS t(cg)
           FOR XML PATH('')
       ),
       1,
       2,
       ''
            ) AS output_columns,
       STUFF(
       (
           SELECT DISTINCT
                  ', ' + cg.value('(@Column)[1]', 'VARCHAR(128)')
           FROM i.nodes('./IndexScan/SeekPredicates/SeekPredicateNew//ColumnReference') AS t(cg)
           FOR XML PATH('')
       ),
       1,
       2,
       ''
            ) AS seek_columns,
       i.value('(./IndexScan/Predicate/ScalarOperator/@ScalarString)[1]', 'VARCHAR(4000)') AS Predicate,
       cp.usecounts,
       tab.query_plan
FROM
(
    SELECT qs.plan_handle,
           tp.query_plan
    FROM
    (
        SELECT DISTINCT
               plan_handle
        FROM sys.dm_exec_query_stats WITH (NOLOCK)
    ) AS qs
        OUTER APPLY sys.dm_exec_query_plan(qs.plan_handle) tp
) AS tab(plan_handle, query_plan)
    INNER JOIN sys.dm_exec_cached_plans AS cp
        ON tab.plan_handle = cp.plan_handle
    CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/*') AS q(n)
    CROSS APPLY n.nodes('.//RelOp[IndexScan[@Lookup="1"] and IndexScan/Object[@Schema!="[sys]"]]') AS s(i)
ORDER BY cp.usecounts DESC
OPTION (RECOMPILE, MAXDOP 1);
