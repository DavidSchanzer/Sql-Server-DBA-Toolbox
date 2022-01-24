-- Open transactions with text and plans
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists information on each open transaction
-- From https://www.sqlskills.com/blogs/paul/script-open-transactions-with-text-and-plans/

SELECT [s_tst].[session_id],
       [s_es].[login_name] AS [Login Name],
       DB_NAME(s_tdt.database_id) AS [Database],
       [s_tdt].[database_transaction_begin_time] AS [Begin Time],
       [s_tdt].[database_transaction_log_bytes_used] AS [Log Bytes],
       [s_tdt].[database_transaction_log_bytes_reserved] AS [Log Rsvd],
       [s_est].text AS [Last T-SQL Text],
       [s_eqp].[query_plan] AS [Last Plan]
FROM sys.dm_tran_database_transactions [s_tdt]
    JOIN sys.dm_tran_session_transactions [s_tst]
        ON [s_tst].[transaction_id] = [s_tdt].[transaction_id]
    JOIN sys.[dm_exec_sessions] [s_es]
        ON [s_es].[session_id] = [s_tst].[session_id]
    JOIN sys.dm_exec_connections [s_ec]
        ON [s_ec].[session_id] = [s_tst].[session_id]
    LEFT OUTER JOIN sys.dm_exec_requests [s_er]
        ON [s_er].[session_id] = [s_tst].[session_id]
    CROSS APPLY sys.dm_exec_sql_text([s_ec].[most_recent_sql_handle]) AS [s_est]
    OUTER APPLY sys.dm_exec_query_plan([s_er].[plan_handle]) AS [s_eqp]
ORDER BY [Begin Time] ASC;
GO
