-- Plan Cache queries - query plans that may utilize parallelism
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists all queries in the Plan Cache that may go parallel.

SELECT TOP (50)
       OBJECT_NAME(p.objectid, p.dbid) AS [object_name],
       ps.total_worker_time / ps.execution_count AS avg_worker_time,
       ps.execution_count,
       ps.total_worker_time,
       ps.total_logical_reads,
       ps.total_elapsed_time,
       p.query_plan,
       q.text,
       cp.plan_handle
FROM sys.dm_exec_procedure_stats ps
    INNER JOIN sys.dm_exec_cached_plans cp
        ON ps.plan_handle = cp.plan_handle
    CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) p
    CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS q
WHERE cp.cacheobjtype = 'Compiled Plan'
      AND p.query_plan.value(
                                'declare namespace p="http://schemas.microsoft.com/sqlserver/2004/07/showplan";max(//p:RelOp/@Parallel)',
                                'float'
                            ) > 0
ORDER BY ps.total_worker_time / ps.execution_count DESC;
