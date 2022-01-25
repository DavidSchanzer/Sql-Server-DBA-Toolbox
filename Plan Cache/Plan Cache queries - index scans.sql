-- Plan Cache queries - index scans
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists all queries in the Plan Cache that have any index scans.
-- From https://www.simple-talk.com/sql/performance/identifying-and-solving-index-scan-problems/

;WITH XMLNAMESPACES
(
    DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
)
SELECT qp.query_plan,
       qt.text,
       qs.statement_start_offset,
       qs.statement_end_offset,
       qs.creation_time,
       qs.last_execution_time,
       qs.execution_count,
       qs.total_worker_time,
       qs.last_worker_time,
       qs.min_worker_time,
       qs.max_worker_time,
       qs.total_physical_reads,
       qs.last_physical_reads,
       qs.min_physical_reads,
       qs.max_physical_reads,
       qs.total_logical_writes,
       qs.last_logical_writes,
       qs.min_logical_writes,
       qs.max_logical_writes,
       qs.total_logical_reads,
       qs.last_logical_reads,
       qs.min_logical_reads,
       qs.max_logical_reads,
       qs.total_elapsed_time,
       qs.last_elapsed_time,
       qs.min_elapsed_time,
       qs.max_elapsed_time,
       qs.total_rows,
       qs.last_rows,
       qs.min_rows,
       qs.max_rows
FROM sys.dm_exec_query_stats AS qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
    CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE qp.query_plan.exist('//RelOp[@LogicalOp="Index Scan"
            or @LogicalOp="Clustered Index Scan"
            or @LogicalOp="Table Scan"]') = 1;
GO
