-- Mining the Query Store - biggest average logical I/O reads
-- Adapted from https://learn.microsoft.com/en-us/sql/relational-databases/performance/tune-performance-with-the-query-store?view=sql-server-ver16
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script identifies queries that had the biggest average logical I/O reads in last 24 hours, with corresponding average row count and execution count.

CREATE TABLE #BiggestAverageLogicalIOReads
(
    database_name SYSNAME NOT NULL,
    avg_logical_io_reads FLOAT NOT NULL,
    query_sql_text NVARCHAR(MAX) NOT NULL,
    query_id BIGINT NOT NULL,
    query_text_id BIGINT NOT NULL,
    plan_id BIGINT NOT NULL,
    runtime_stats_id BIGINT NOT NULL,
    start_time DATETIMEOFFSET NOT NULL,
    end_time DATETIMEOFFSET NOT NULL,
    avg_rowcount FLOAT NOT NULL,
    count_executions BIGINT NOT NULL
);

INSERT INTO #BiggestAverageLogicalIOReads
EXEC sp_ineachdb @command = 'SELECT TOP (1) DB_NAME(), rs.avg_logical_io_reads, qt.query_sql_text,
				q.query_id, qt.query_text_id, p.plan_id, rs.runtime_stats_id,
				rsi.start_time, rsi.end_time, rs.avg_rowcount, rs.count_executions
			FROM sys.query_store_query_text AS qt
			JOIN sys.query_store_query AS q
				ON qt.query_text_id = q.query_text_id
			JOIN sys.query_store_plan AS p
				ON q.query_id = p.query_id
			JOIN sys.query_store_runtime_stats AS rs
				ON p.plan_id = rs.plan_id
			JOIN sys.query_store_runtime_stats_interval AS rsi
				ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
			WHERE rsi.start_time >= DATEADD(hour, -24, GETUTCDATE())
			AND rs.avg_logical_io_reads > 1000000
			ORDER BY rs.avg_logical_io_reads DESC;',
                 @user_only = 1;

SELECT database_name,
       avg_logical_io_reads,
       query_sql_text,
       query_id,
       query_text_id,
       plan_id,
       runtime_stats_id,
       start_time,
       end_time,
       avg_rowcount,
       count_executions
FROM #BiggestAverageLogicalIOReads;

DROP TABLE #BiggestAverageLogicalIOReads;
GO
