-- Mining the Query Store - looking for text strings in queries
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists all queries in the Query Store that contain a specific string or stored procedure name.
-- From https://www.sqlskills.com/blogs/erin/why-you-need-query-store-part-iii-proactively-analyze-your-workload/

-- This first query is looking for a specific string
SELECT
     [qsq].[query_id],
     [qsp].[plan_id],
     [qst].[query_sql_text],
     ( select [qst].[query_sql_text] for xml path, type ) AS query_sql_text_XML,
     TRY_CONVERT(XML, [qsp].[query_plan]) AS [QueryPlan_XML],
     rs.first_execution_time AT TIME ZONE 'AUS Eastern Standard Time' AS 'AEST first_execution_time',
     rs.last_execution_time AT TIME ZONE 'AUS Eastern Standard Time' AS 'AEST last_execution_time',
     rs.count_executions,
     rs.avg_duration / 1000000.0 AS [avg_duration_secs],
     rs.last_duration / 1000000.0 AS [last_duration_secs],
     rs.min_duration / 1000000.0 AS [min_duration_secs],
     rs.max_duration / 1000000.0 AS [max_duration_secs],
     rs.stdev_duration / 1000000.0 AS [stdev_duration_secs],
     rs.avg_cpu_time,
     rs.last_cpu_time,
     rs.min_cpu_time,
     rs.max_cpu_time,
     rs.stdev_cpu_time,
     rs.avg_logical_io_reads,
     rs.last_logical_io_reads,
     rs.min_logical_io_reads,
     rs.max_logical_io_reads,
     rs.stdev_logical_io_reads,
     rs.avg_logical_io_writes,
     rs.last_logical_io_writes,
     rs.min_logical_io_writes,
     rs.max_logical_io_writes,
     rs.stdev_logical_io_writes,
     rs.avg_physical_io_reads,
     rs.last_physical_io_reads,
     rs.min_physical_io_reads,
     rs.max_physical_io_reads,
     rs.stdev_physical_io_reads,
     rs.avg_clr_time,
     rs.last_clr_time,
     rs.min_clr_time,
     rs.max_clr_time,
     rs.stdev_clr_time,
     rs.avg_dop,
     rs.last_dop,
     rs.min_dop,
     rs.max_dop,
     rs.stdev_dop,
     rs.avg_query_max_used_memory,
     rs.last_query_max_used_memory,
     rs.min_query_max_used_memory,
     rs.max_query_max_used_memory,
     rs.stdev_query_max_used_memory,
     rs.avg_rowcount,
     rs.last_rowcount,
     rs.min_rowcount,
     rs.max_rowcount,
     rs.stdev_rowcount,
     rs.avg_num_physical_io_reads,
     rs.last_num_physical_io_reads,
     rs.min_num_physical_io_reads,
     rs.max_num_physical_io_reads,
     rs.stdev_num_physical_io_reads,
     rs.avg_log_bytes_used,
     rs.last_log_bytes_used,
     rs.min_log_bytes_used,
     rs.max_log_bytes_used,
     rs.stdev_log_bytes_used,
     rs.avg_tempdb_space_used,
     rs.last_tempdb_space_used,
     rs.min_tempdb_space_used,
     rs.max_tempdb_space_used,
     rs.stdev_tempdb_space_used
FROM [sys].[query_store_query] [qsq]
JOIN [sys].[query_store_query_text] [qst]
     ON [qsq].[query_text_id] = [qst].[query_text_id]
JOIN [sys].[query_store_plan] [qsp]
     ON [qsq].[query_id] = [qsp].[query_id]
JOIN [sys].[query_store_runtime_stats] [rs]
     ON [qsp].[plan_id] = [rs].[plan_id]
WHERE [qst].[query_sql_text] LIKE '%InsertQueryTextHere%'
AND [rs].[last_execution_time] AT TIME ZONE 'AUS Eastern Standard Time' BETWEEN 'yyyy-mm-dd hh:mm +11:00' AND 'yyyy-mm-dd hh:mm +11:00'
ORDER BY rs.first_execution_time;

-- This second query is looking for a specific stored procedure name as the object
SELECT
     [qsq].[query_id],
     [qsp].[plan_id],
     [qsq].[object_id],
     [qst].[query_sql_text],
     ConvertedPlan = TRY_CONVERT(XML, [qsp].[query_plan])
FROM [sys].[query_store_query] [qsq]
JOIN [sys].[query_store_query_text] [qst]
     ON [qsq].[query_text_id] = [qst].[query_text_id]
JOIN [sys].[query_store_plan] [qsp]
     ON [qsq].[query_id] = [qsp].[query_id]
WHERE [qsq].[object_id] = OBJECT_ID(N'<SchemaName>.<StoredProcedureName>');
GO
