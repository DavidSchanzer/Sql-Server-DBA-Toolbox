-- Most expensive queries using Query Store
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists the top 20 most expensive queries in the last N days, by default ordered descending by Total CPU.
-- From https://matthewmcgiffen.com/2017/11/01/capture-the-most-expensive-queries-across-your-sql-server-using-query-store/

-- Gather and report on most resource hungry queries
DECLARE @Reportinginterval INT;
DECLARE @Database sysname;
DECLARE @StartDateText VARCHAR(30);
DECLARE @TotalExecutions DECIMAL(20, 3);
DECLARE @TotalDuration DECIMAL(20, 3);
DECLARE @TotalCPU DECIMAL(20, 3);
DECLARE @TotalLogicalReads DECIMAL(20, 3);
DECLARE @SQL VARCHAR(MAX);

-- Set Reporting interval in days
SET @Reportinginterval = 1;

SET @StartDateText = CAST(DATEADD(DAY, -@Reportinginterval, GETUTCDATE()) AS VARCHAR(30));

-- Cursor to step through the databases
DECLARE curDatabases CURSOR LOCAL FAST_FORWARD FOR
SELECT name
FROM sys.databases
WHERE is_query_store_on = 1
ORDER BY name;

-- Temp table to store the results
DROP TABLE IF EXISTS #Stats;
CREATE TABLE #Stats
(
    DatabaseName sysname NOT NULL,
    SchemaName sysname NULL,
    ObjectName sysname NULL,
    QueryText VARCHAR(MAX) NOT NULL,
    TotalExecutions BIGINT NOT NULL,
    TotalDuration DECIMAL(20, 3) NOT NULL,
    TotalCPU DECIMAL(20, 3) NOT NULL,
    TotalLogicalReads BIGINT NOT NULL
);

OPEN curDatabases;
FETCH NEXT FROM curDatabases
INTO @Database;

-- Loop through the datbases and gather the stats
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL
        = '
	   USE [' + @Database
          + ']
	   INSERT intO #Stats
	   SELECT 
		  DB_NAME(),
		  s.name AS SchemaName,
		  o.name AS ObjectName,
		  t.query_sql_text AS QueryText,
		  SUM(rs.count_executions) AS TotalExecutions,
		  SUM(rs.avg_duration * rs.count_executions) AS TotalDuration,
		  SUM(rs.avg_cpu_time * rs.count_executions) AS TotalCPU,
		  SUM(rs.avg_logical_io_reads * rs.count_executions) AS TotalLogicalReads
	   FROM sys.query_store_query q
	   INNER JOIN sys.query_store_query_text t
		  ON q.query_text_id = t.query_text_id
	   INNER JOIN sys.query_store_plan p
		  ON q.query_id = p.query_id
	   INNER JOIN sys.query_store_runtime_stats rs
		  ON p.plan_id = rs.plan_id
	   INNER JOIN sys.query_store_runtime_stats_interval rsi
		  ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
	   LEFT JOIN sys.objects o
		  ON q.OBJECT_ID = o.OBJECT_ID
	   LEFT JOIN sys.schemas s
		  ON o.schema_id = s.schema_id     
	   WHERE rsi.start_time > ''' + @StartDateText
          + '''
	   GROUP BY s.name, o.name, t.query_sql_text
	   OPTION(RECOMPILE);';

	PRINT @SQL;
    EXEC (@SQL);

    FETCH NEXT FROM curDatabases
    INTO @Database;
END;

CLOSE curDatabases;
DEALLOCATE curDatabases;

-- Aggregate some totals
SELECT @TotalExecutions = SUM(TotalExecutions),
       @TotalDuration = SUM(TotalDuration),
       @TotalCPU = SUM(TotalCPU),
       @TotalLogicalReads = SUM(TotalLogicalReads)
FROM #Stats;

-- Produce output
SELECT TOP (20)
       DatabaseName,
       SchemaName,
       ObjectName,
       QueryText,
       TotalExecutions,
       CAST((TotalExecutions / @TotalExecutions) * 100 AS DECIMAL(5, 2)) AS [TotalExecutions %],
       CAST(TotalDuration / 1000000 AS DECIMAL(19, 2)) AS [TotalDuration(s)],
       CAST((TotalDuration / @TotalDuration) * 100 AS DECIMAL(5, 2)) AS [TotalDuration %],
       CAST((TotalDuration / TotalExecutions) / 1000 AS DECIMAL(19, 2)) AS [AverageDuration(ms)],
       CAST(TotalCPU / 1000000 AS DECIMAL(19, 2)) [TotalCPU(s)],
       CAST((TotalCPU / @TotalCPU) * 100 AS DECIMAL(5, 2)) AS [TotalCPU %],
       CAST((TotalCPU / TotalExecutions) / 1000 AS DECIMAL(19, 2)) AS [AverageCPU(ms)],
       TotalLogicalReads,
       CAST((TotalLogicalReads / @TotalLogicalReads) * 100 AS DECIMAL(5, 2)) AS [TotalLogicalReads %],
       CAST((TotalLogicalReads / TotalExecutions) AS DECIMAL(19, 2)) AS AverageLogicalReads
FROM #Stats
--Order by the resource you're most interested in

--ORDER BY TotalExecutions DESC
--ORDER BY TotalDuration DESC
--ORDER BY TotalCPU DESC;
ORDER BY TotalLogicalReads DESC

DROP TABLE #Stats;
