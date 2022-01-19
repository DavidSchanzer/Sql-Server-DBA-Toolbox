-- From https://www.sqlskills.com/blogs/erin/why-you-need-query-store-part-iii-proactively-analyze-your-workload/
-- This first query is looking for a specific string
SELECT
     [qsq].[query_id],
     [qsp].[plan_id],
     [rs].[last_execution_time] AT TIME ZONE 'AUS Eastern Standard Time' AS [AEST StartTime],
     [rs].[avg_duration] / 1000000 AS [avg_duration_secs],
     [rs].[avg_logical_io_reads],
     [qst].[query_sql_text],
     TRY_CONVERT(XML, [qsp].[query_plan]) AS [QueryPlan_XML]
FROM [sys].[query_store_query] [qsq]
JOIN [sys].[query_store_query_text] [qst]
     ON [qsq].[query_text_id] = [qst].[query_text_id]
JOIN [sys].[query_store_plan] [qsp]
     ON [qsq].[query_id] = [qsp].[query_id]
JOIN [sys].[query_store_runtime_stats] [rs]
     ON [qsp].[plan_id] = [rs].[plan_id]
WHERE [qst].[query_sql_text] LIKE '%nhunter%';

-- This second query is looking for a specific stored procedure name as the object
SELECT
     [qsq].[query_id],
     [qsp].[plan_id],
     [qsq].[object_id],
     [qst].[query_sql_text],
     ConvertedPlan = TRY_CONVERT(XML, [qsp].[query_plan]), *
FROM [sys].[query_store_query] [qsq]
JOIN [sys].[query_store_query_text] [qst]
     ON [qsq].[query_text_id] = [qst].[query_text_id]
JOIN [sys].[query_store_plan] [qsp]
     ON [qsq].[query_id] = [qsp].[query_id]
WHERE [qsq].[object_id] = OBJECT_ID(N'dbo.sp_refresh_FACT_NOTIFICATION_ONEVIEW');
GO
