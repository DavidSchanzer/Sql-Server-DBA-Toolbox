-- From https://sqlperformance.com/2019/10/t-sql-queries/death-by-a-thousand-cuts
;WITH qh AS
(
    SELECT TOP (25) query_hash, COUNT(*) AS COUNT
    FROM sys.dm_exec_query_stats
    GROUP BY query_hash
    ORDER BY COUNT(*) DESC
),
qs AS
(
    SELECT obj = COALESCE(ps.object_id,   fs.object_id,   ts.object_id),
            db = COALESCE(ps.database_id, fs.database_id, ts.database_id),
            qs.query_hash, qs.query_plan_hash, qs.execution_count,
            qs.sql_handle, qs.plan_handle
    FROM sys.dm_exec_query_stats AS qs
    INNER JOIN qh ON qs.query_hash = qh.query_hash
    LEFT OUTER JOIN sys.dm_exec_procedure_stats AS [ps]
      ON [qs].[sql_handle] = [ps].[sql_handle]
    LEFT OUTER JOIN sys.dm_exec_function_stats AS [fs]
      ON [qs].[sql_handle] = [fs].[sql_handle]
    LEFT OUTER JOIN sys.dm_exec_trigger_stats AS [ts]
      ON [qs].[sql_handle] = [ts].[sql_handle]
)
SELECT TOP (50)
  object_name = OBJECT_NAME(qs.obj, qs.db), 
  query_hash,
  query_plan_hash,
  SUM([qs].[execution_count]) AS [ExecutionCount],
  MAX([st].[text]) AS [QueryText]
  FROM qs 
  CROSS APPLY sys.dm_exec_sql_text ([qs].[sql_handle]) AS [st]
  CROSS APPLY sys.dm_exec_query_plan ([qs].[plan_handle]) AS [qp]
  GROUP BY qs.obj, qs.db, qs.query_hash, qs.query_plan_hash
  ORDER BY ExecutionCount DESC;
