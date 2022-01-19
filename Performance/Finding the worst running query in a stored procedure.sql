SELECT CAST(qp.query_plan AS XML) AS XML_Plan,
	SUBSTRING(st.text,qs.statement_start_offset/2+1,
            ((CASE WHEN qs.statement_end_offset = -1 THEN DATALENGTH(st.text)
                ELSE qs.statement_end_offset END) - qs.statement_start_offset)/2 + 1)  AS SqlText,
	qs.*
FROM sys.dm_exec_query_stats qs
JOIN sys.dm_exec_procedure_stats ps
	ON qs.sql_handle = ps.sql_handle
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
CROSS APPLY sys.dm_exec_text_query_plan(qs.plan_handle, 
		statement_start_offset, statement_end_offset) qp
WHERE ps.object_id = object_id('papregdb.dbo.spa_followup_2006_proc_client')
ORDER BY last_logical_reads DESC;
