-- Mining the Query Store - queries with multiple plans
-- Adapted from https://learn.microsoft.com/en-us/sql/relational-databases/performance/tune-performance-with-the-query-store?view=sql-server-ver16
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script identifies queries that are candidates for regressions due to plan choice change, along with all plans.

CREATE TABLE #QueriesWithMultiplePlans
(
    database_name SYSNAME NOT NULL,
    query_id BIGINT NOT NULL,
    ContainingObject SYSNAME NULL,
    query_sql_text NVARCHAR(MAX) NOT NULL,
    plan_id BIGINT NOT NULL,
	plan_xml NVARCHAR(MAX) NOT NULL,
	last_compile_start_time DATETIMEOFFSET NULL,
	last_execution_time DATETIMEOFFSET NULL
);

INSERT INTO #QueriesWithMultiplePlans
EXEC sp_ineachdb @command = 'WITH Query_MultPlans
AS
(
	SELECT COUNT(*) AS cnt, q.query_id
	FROM sys.query_store_query_text AS qt
	JOIN sys.query_store_query AS q
		ON qt.query_text_id = q.query_text_id
	JOIN sys.query_store_plan AS p
		ON p.query_id = q.query_id
	GROUP BY q.query_id
	HAVING COUNT(distinct plan_id) > 1
)
SELECT DB_NAME(), q.query_id, object_name(object_id) AS ContainingObject,
    query_sql_text, plan_id, p.query_plan AS plan_xml,
    p.last_compile_start_time, p.last_execution_time
FROM Query_MultPlans AS qm
JOIN sys.query_store_query AS q
    ON qm.query_id = q.query_id
JOIN sys.query_store_plan AS p
    ON q.query_id = p.query_id
JOIN sys.query_store_query_text qt
    ON qt.query_text_id = q.query_text_id;',
                 @user_only = 1;

SELECT database_name,
       query_id,
       ContainingObject,
       query_sql_text,
       plan_id,
       plan_xml,
       last_compile_start_time,
       last_execution_time
FROM #QueriesWithMultiplePlans
ORDER BY database_name, query_id, plan_id;

DROP TABLE #QueriesWithMultiplePlans;
GO
