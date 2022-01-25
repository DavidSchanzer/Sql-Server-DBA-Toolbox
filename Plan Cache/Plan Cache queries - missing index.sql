-- Plan Cache queries - missing index
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists all queries in the Plan Cache that have any missing indexes.

SELECT qp.query_plan,
       qs.total_worker_time / qs.execution_count AS AvgCPU,
       qs.total_elapsed_time / qs.execution_count AS AvgDuration,
       (qs.total_logical_reads + qs.total_physical_reads) / qs.execution_count AS AvgReads,
       qs.execution_count,
       SUBSTRING(   st.text,
                    (qs.statement_start_offset / 2) + 1,
                    ((CASE qs.statement_end_offset
                          WHEN -1 THEN
                              DATALENGTH(st.text)
                          ELSE
                              qs.statement_end_offset
                      END - qs.statement_start_offset
                     ) / 2
                    ) + 1
                ) AS txt,
       qp.query_plan.value(
                              'declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/@Impact)[1]',
                              'decimal(18,4)'
                          ) * qs.execution_count AS TotalImpact,
       qp.query_plan.value(
                              'declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Database)[1]',
                              'varchar(100)'
                          ) AS [DATABASE],
       qp.query_plan.value(
                              'declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Table)[1]',
                              'varchar(100)'
                          ) AS [TABLE],
       qs.last_execution_time [Last Execution Time]
FROM sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
    CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE qp.query_plan.exist('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan";/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex[@Database!="m"]') = 1
      AND qp.query_plan.value(
                                 'declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Database)[1]',
                                 'varchar(100)'
                             ) NOT LIKE '_msdb_%'
ORDER BY TotalImpact DESC;
