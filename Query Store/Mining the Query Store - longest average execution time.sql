-- Mining the Query Store - longest average execution time
-- Adapted from https://learn.microsoft.com/en-us/sql/relational-databases/performance/tune-performance-with-the-query-store?view=sql-server-ver16
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script identifies queries with the longest average execution time within last hour.

CREATE TABLE #LongestAverageExecutionTime
(
	database_name		SYSNAME NOT NULL,
    avg_duration		INT NOT NULL,
    query_sql_text		NVARCHAR(MAX) NOT NULL,
    query_id			BIGINT NOT NULL,
    query_text_id		BIGINT NOT NULL,
    plan_id				BIGINT NOT NULL,
    CurrentUTCTime		DATETIME NOT NULL,
    last_execution_time	DATETIMEOFFSET NOT NULL
);

INSERT INTO #LongestAverageExecutionTime
EXEC sp_ineachdb @command = 
	'SELECT TOP (1) DB_NAME(), rs.avg_duration, qt.query_sql_text, q.query_id,
			qt.query_text_id, p.plan_id, GETUTCDATE() AS CurrentUTCTime,
			rs.last_execution_time
		FROM sys.query_store_query_text AS qt
		JOIN sys.query_store_query AS q
			ON qt.query_text_id = q.query_text_id
		JOIN sys.query_store_plan AS p
			ON q.query_id = p.query_id
		JOIN sys.query_store_runtime_stats AS rs
			ON p.plan_id = rs.plan_id
		WHERE rs.last_execution_time > DATEADD(hour, -1, GETUTCDATE())\
		AND rs.avg_duration > 100000
		ORDER BY rs.avg_duration DESC;',
                 @user_only = 1;

SELECT database_name,
       avg_duration,
       query_sql_text,
       query_id,
       query_text_id,
       plan_id,
       CurrentUTCTime,
       last_execution_time
FROM #LongestAverageExecutionTime;

DROP TABLE #LongestAverageExecutionTime;
GO
