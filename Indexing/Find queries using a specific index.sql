/* Execution plan cache */
SELECT  DB_NAME(sqltext.dbid) AS DatabaseName, querystats.plan_handle, querystats.query_hash,
        SUBSTRING(sqltext.text, ( querystats.statement_start_offset / 2 ) + 1, ( CASE querystats.statement_end_offset
                                                                                   WHEN -1 THEN DATALENGTH(sqltext.text)
                                                                                   ELSE querystats.statement_end_offset
                                                                                 END - querystats.statement_start_offset ) / 2 + 1) AS sqltext,
        querystats.execution_count, querystats.total_logical_reads, querystats.total_logical_writes, querystats.creation_time, querystats.last_execution_time,
        CAST(query_plan AS XML) AS plan_xml
FROM    sys.dm_exec_query_stats AS querystats
        CROSS APPLY sys.dm_exec_text_query_plan(querystats.plan_handle, querystats.statement_start_offset, querystats.statement_end_offset) AS textplan
        CROSS APPLY sys.dm_exec_sql_text(querystats.sql_handle) AS sqltext
WHERE   textplan.query_plan LIKE '%IX_CRPatient_DateOfBirth%'
        AND SUBSTRING(sqltext.text, ( querystats.statement_start_offset / 2 ) + 1, ( CASE querystats.statement_end_offset
                                                                                       WHEN -1 THEN DATALENGTH(sqltext.text)
                                                                                       ELSE querystats.statement_end_offset
                                                                                     END - querystats.statement_start_offset ) / 2 + 1) LIKE '%SELECT %'
ORDER BY querystats.last_execution_time DESC
OPTION  ( RECOMPILE );
GO
