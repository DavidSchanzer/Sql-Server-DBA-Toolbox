-- Plan Cache queries - find queries using any index hint
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists all queries in the Plan Cache that use any index hint.

SELECT DB_NAME(sqltext.dbid) AS DatabaseName,
       querystats.plan_handle,
       querystats.query_hash,
       SUBSTRING(
                    sqltext.text,
                    (querystats.statement_start_offset / 2) + 1,
                    (CASE querystats.statement_end_offset
                         WHEN -1 THEN
                             DATALENGTH(sqltext.text)
                         ELSE
                             querystats.statement_end_offset
                     END - querystats.statement_start_offset
                    ) / 2 + 1
                ) AS sqltext,
       querystats.execution_count,
       querystats.total_logical_reads,
       querystats.total_logical_writes,
       querystats.creation_time,
       querystats.last_execution_time,
       CAST(textplan.query_plan AS XML) AS plan_xml
FROM sys.dm_exec_query_stats AS querystats
    CROSS APPLY sys.dm_exec_text_query_plan(
                                               querystats.plan_handle,
                                               querystats.statement_start_offset,
                                               querystats.statement_end_offset
                                           ) AS textplan
    CROSS APPLY sys.dm_exec_sql_text(querystats.sql_handle) AS sqltext
WHERE textplan.query_plan LIKE N'%ForcedIndex="1"%'
      AND UPPER(sqltext.text) LIKE N'%INDEX%'
OPTION (RECOMPILE);
GO
