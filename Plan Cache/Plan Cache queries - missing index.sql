SELECT qp.query_plan
, total_worker_time/execution_count AS AvgCPU 
, total_elapsed_time/execution_count AS AvgDuration 
, (total_logical_reads+total_physical_reads)/execution_count AS AvgReads 
, execution_count 
, SUBSTRING(st.text, (qs.statement_start_offset/2)+1 , ((CASE qs.statement_end_offset WHEN -1 THEN datalength(st.TEXT) ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) + 1) AS txt 
, qp.query_plan.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/@Impact)[1]' , 'decimal(18,4)') * execution_count AS TotalImpact
, qp.query_plan.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Database)[1]' , 'varchar(100)') AS [DATABASE]
, qp.query_plan.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Table)[1]' , 'varchar(100)') AS [TABLE]
,last_execution_time [Last Execution Time]
FROM sys.dm_exec_query_stats qs
cross apply sys.dm_exec_sql_text(sql_handle) st
cross apply sys.dm_exec_query_plan(plan_handle) qp
WHERE qp.query_plan.exist('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan";/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex[@Database!="m"]') = 1
AND qp.query_plan.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Database)[1]' , 'varchar(100)') NOT LIKE '_msdb_%'
--AND SUBSTRING(st.text, (qs.statement_start_offset/2)+1 , ((CASE qs.statement_end_offset WHEN -1 THEN datalength(st.TEXT) ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) + 1) NOT LIKE '%#%'
ORDER BY TotalImpact DESC
