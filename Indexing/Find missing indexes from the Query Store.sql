-- Find missing indexes from the Query Store
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists missing indices from the Query Store during the last week, where there are more than 100 million estimated logical reads
-- in total.
-- From https://littlekendra.com/2016/01/19/find-missing-index-requests-query-store-sql-2016/

DECLARE @DatabaseName sysname,
        @QueryPlanHash BINARY(8),
        @QueryPlanHashStr NVARCHAR(20),
        @QuerySQLText NVARCHAR(MAX),
        @QueryPlan NVARCHAR(MAX),
        @sql NVARCHAR(MAX)
    =   N'
	SELECT DB_NAME() AS DatabaseName,
		   SUM(qrs.count_executions) * SUM(qrs.count_executions * qrs.avg_logical_io_reads) / SUM(qrs.count_executions) AS TotalEstimatedLogicalReads,
		   SUM(qrs.count_executions) AS TotalExecutions,
		   SUM(qrs.count_executions * qrs.avg_logical_io_reads) / SUM(qrs.count_executions) AS AvgEstimatedLogicalReads,
		   TRY_CONVERT(XML,
		   (
			   SELECT TOP 1
					  qsp2.query_plan
			   FROM sys.query_store_plan qsp2
			   WHERE qsp2.query_id = qsq.query_id
				 AND qsp2.query_plan LIKE N''%<MissingIndexes>%''
			   ORDER BY qsp2.plan_id DESC
		   )) AS QueryPlan,
		   qsq.query_id AS QueryID,
		   qsq.query_hash AS QueryHash,
		   (
			   SELECT TOP 1
					  qsp2.query_plan_hash
			   FROM sys.query_store_plan qsp2
			   WHERE qsp2.query_id = qsq.query_id
				 AND qsp2.query_plan LIKE N''%<MissingIndexes>%''
			   ORDER BY qsp2.plan_id DESC
		   ) AS QueryPlanHash,
		   MAX(qsrsi.start_time) AS QueryStartTime
	FROM sys.query_store_query qsq
		JOIN sys.query_store_plan qsp
			ON qsq.query_id = qsp.query_id
		CROSS APPLY
	(SELECT TRY_CONVERT(XML, qsp.query_plan) AS query_plan_xml) AS qpx
		JOIN sys.query_store_runtime_stats qrs
			ON qsp.plan_id = qrs.plan_id
		JOIN sys.query_store_runtime_stats_interval qsrsi
			ON qrs.runtime_stats_interval_id = qsrsi.runtime_stats_interval_id
	WHERE qsp.query_plan LIKE N''%<MissingIndexes>%''
		  AND qsrsi.start_time >= DATEADD(day, -7, SYSDATETIME())	-- Only show missing indexes detected in the last 7 days
	GROUP BY qsq.query_id,
			 qsq.query_hash;';

IF OBJECT_ID('tempdb..#MissingIndices') IS NOT NULL
    DROP TABLE #MissingIndices;

CREATE TABLE #MissingIndices
(
    DatabaseName sysname NOT NULL,
    TotalEstimatedLogicalReads BIGINT NOT NULL,
    TotalExecutions INT NOT NULL,
    AvgEstimatedLogicalReads BIGINT NOT NULL,
    QueryPlan XML NULL,
    QueryID INT NOT NULL,
    QueryHash BINARY(8) NOT NULL,
    QueryPlanHash BINARY(8) NOT NULL,
    QueryStartTime DATETIMEOFFSET NOT NULL
);

INSERT INTO #MissingIndices
(
    DatabaseName,
    TotalEstimatedLogicalReads,
    TotalExecutions,
    AvgEstimatedLogicalReads,
    QueryPlan,
    QueryID,
    QueryHash,
    QueryPlanHash,
    QueryStartTime
)
EXEC dbo.sp_ineachdb @command = @sql, @user_only = 1;

IF OBJECT_ID('tempdb..#FullMissing') IS NOT NULL
    DROP TABLE #FullMissing;

    ;WITH XMLNAMESPACES
     (
         DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
     )
SELECT mi.DatabaseName,
       mi.TotalEstimatedLogicalReads,
       mi.TotalExecutions,
       mi.AvgEstimatedLogicalReads,
       StmtXML.value('(QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Schema)[1]', 'sysname') AS SchemaName,
       StmtXML.value('(QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Table)[1]', 'sysname') AS TableName,
       StmtXML.value('(QueryPlan/MissingIndexes/MissingIndexGroup/@Impact)[1]', 'float') AS Impact,
       STUFF(
       (
           SELECT DISTINCT
                  ', ' + c.value('(@Name)[1]', 'sysname')
           FROM StmtXML.nodes('//ColumnGroup') AS t(cg)
               CROSS APPLY cg.nodes('Column') AS r(c)
           WHERE cg.value('(@Usage)[1]', 'sysname') = 'EQUALITY'
           FOR XML PATH('')
       ),
       1,
       2,
       ''
            ) AS EqualityColumns,
       STUFF(
       (
           SELECT DISTINCT
                  ', ' + c.value('(@Name)[1]', 'sysname')
           FROM StmtXML.nodes('//ColumnGroup') AS t(cg)
               CROSS APPLY cg.nodes('Column') AS r(c)
           WHERE cg.value('(@Usage)[1]', 'sysname') = 'INEQUALITY'
           FOR XML PATH('')
       ),
       1,
       2,
       ''
            ) AS InequalityColumns,
       STUFF(
       (
           SELECT DISTINCT
                  ', ' + c.value('(@Name)[1]', 'sysname')
           FROM StmtXML.nodes('//ColumnGroup') AS t(cg)
               CROSS APPLY cg.nodes('Column') AS r(c)
           WHERE cg.value('(@Usage)[1]', 'sysname') = 'INCLUDE'
           FOR XML PATH('')
       ),
       1,
       2,
       ''
            ) AS IncludeColumns,
       mi.QueryPlanHash,
       mi.QueryStartTime
INTO #FullMissing
FROM #MissingIndices AS mi
    CROSS APPLY QueryPlan.nodes('//StmtSimple') AS stmt(StmtXML);

IF OBJECT_ID('tempdb..#OutputMissing') IS NOT NULL
    DROP TABLE #OutputMissing;

CREATE TABLE #OutputMissing
(
    DatabaseName sysname NOT NULL,
    SchemaName sysname NOT NULL,
    TableName sysname NOT NULL,
    TotalEstimatedLogicalReads BIGINT NOT NULL,
    AvgEstimatedLogicalReads BIGINT NOT NULL,
    Impact FLOAT NOT NULL,
    TotalExecutions INT NOT NULL,
    EqualityColumns NVARCHAR(MAX) NULL,
    InequalityColumns NVARCHAR(MAX) NULL,
    IncludeColumns NVARCHAR(MAX) NULL,
    QueryPlanHash BINARY(8) NOT NULL,
    MostRecentQueryStartHour DATETIMEOFFSET NOT NULL,
    QueryPlan NVARCHAR(MAX) NULL,
    SampleQueryText NVARCHAR(MAX) NULL
);

INSERT INTO #OutputMissing
(
    DatabaseName,
    SchemaName,
    TableName,
    TotalEstimatedLogicalReads,
    AvgEstimatedLogicalReads,
    Impact,
    TotalExecutions,
    EqualityColumns,
    InequalityColumns,
    IncludeColumns,
    QueryPlanHash,
    MostRecentQueryStartHour,
    QueryPlan,
    SampleQueryText
)
SELECT DatabaseName,
       SchemaName,
       TableName,
       SUM(TotalEstimatedLogicalReads) AS TotalEstimatedLogicalReads,
       SUM(AvgEstimatedLogicalReads) AS AvgEstimatedLogicalReads,
       MAX(Impact) AS Impact,
       SUM(TotalExecutions) AS TotalExecutions,
       EqualityColumns,
       InequalityColumns,
       IncludeColumns,
       QueryPlanHash,
       MAX(QueryStartTime) AS MostRecentQueryStartHour,
       NULL AS QueryPlan,      -- NULL value for the query plan so that it can be updated in the cursor below
       NULL AS SampleQueryText -- NULL value for the sample query text so that it can be updated in the cursor below
FROM #FullMissing
GROUP BY DatabaseName,
         SchemaName,
         TableName,
         EqualityColumns,
         InequalityColumns,
         IncludeColumns,
         QueryPlanHash
HAVING SUM(TotalEstimatedLogicalReads) > 100000000; -- More than 100 million estimated logical reads in total

-- We now have everything we need except the query plan and a sample of a query that requested this missing index.
-- So, we need to retrieve these values from the appropriate database's query store, and we'll update these two NULL values in the #OutputMissing table using an update cursor.
-- Firstly add a clustered index as this is a requirement for an update cursor.
CREATE CLUSTERED INDEX CIX_Output_Missing
ON #OutputMissing (QueryPlanHash);

DECLARE IndexCur CURSOR LOCAL FOR
SELECT DatabaseName,
       QueryPlanHash,
       QueryPlan,
       SampleQueryText
FROM #OutputMissing
FOR UPDATE;

OPEN IndexCur;
FETCH IndexCur
INTO @DatabaseName,
     @QueryPlanHash,
     @QueryPlan,
     @QuerySQLText;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @QueryPlanHashStr = master.sys.fn_varbintohexsubstring(1, @QueryPlanHash, 1, 0);
    SET @sql
        = N'
		SELECT TOP (1) @QueryPlan = CAST(qsp.query_plan AS NVARCHAR(MAX)), @QuerySQLText = qsqt.query_sql_text 
			FROM [' + @DatabaseName + N'].sys.query_store_plan AS qsp 
			INNER JOIN [' + @DatabaseName
          + N'].sys.query_store_query AS qsq ON qsp.query_id = qsq.query_id 
			INNER JOIN [' + @DatabaseName
          + N'].sys.query_store_query_text AS qsqt ON qsqt.query_text_id = qsq.query_text_id 
			WHERE query_plan_hash = ' + @QueryPlanHashStr;

    EXEC sp_executesql @stmt = @sql,
                       @params = N'@QueryPlan NVARCHAR(MAX) OUTPUT, @QuerySQLText NVARCHAR(MAX) OUTPUT',
                       @QueryPlan = @QueryPlan OUTPUT,
                       @QuerySQLText = @QuerySQLText OUTPUT;

    UPDATE #OutputMissing
    SET QueryPlan = @QueryPlan,
        SampleQueryText = @QuerySQLText
    WHERE CURRENT OF IndexCur;

    FETCH IndexCur
    INTO @DatabaseName,
         @QueryPlanHash,
         @QueryPlan,
         @QuerySQLText;
END;

CLOSE IndexCur;
DEALLOCATE IndexCur;

SELECT DatabaseName,
       TotalEstimatedLogicalReads,
       AvgEstimatedLogicalReads,
       Impact,
       TotalExecutions,
       '[' + DatabaseName + '].' + SchemaName + '.' + TableName AS [Table],
       'CREATE NONCLUSTERED INDEX [IX_' + SUBSTRING(TableName, 2, LEN(TableName) - 2) + '_'
       + REPLACE(
                    REPLACE(
                               REPLACE(   ISNULL(EqualityColumns, '') + CASE
                                                                            WHEN InequalityColumns IS NOT NULL THEN
                                                                                '_'
                                                                            ELSE
                                                                                ''
                                                                        END + ISNULL(InequalityColumns, ''),
                                          '[',
                                          ''
                                      ),
                               ']',
                               ''
                           ),
                    ', ',
                    '_'
                ) + CASE
                        WHEN IncludeColumns IS NOT NULL THEN
                            '_includes'
                        ELSE
                            ''
                    END + '] ON ' + '[' + DatabaseName + '].' + SchemaName + '.' + TableName + ' ( '
       + ISNULL(EqualityColumns, '') + CASE
                                           WHEN InequalityColumns IS NULL THEN
                                               ''
                                           ELSE
                                               CASE
                                                   WHEN EqualityColumns IS NULL THEN
                                                       ''
                                                   ELSE
                                                       ','
                                               END + InequalityColumns
                                       END + ' ) ' + CASE
                                                         WHEN IncludeColumns IS NULL THEN
                                                             ''
                                                         ELSE
                                                             'INCLUDE (' + IncludeColumns + ')'
                                                     END + ';' AS CreateIndexStatement,
       EqualityColumns,
       InequalityColumns,
       IncludeColumns,
       SampleQueryText,
       QueryPlanHash,
       TRY_CONVERT(XML, QueryPlan) AS QueryPlan,
       MostRecentQueryStartHour
FROM #OutputMissing
ORDER BY TotalEstimatedLogicalReads DESC;
--ORDER BY Impact DESC;
GO
