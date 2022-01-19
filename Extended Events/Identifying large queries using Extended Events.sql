-- From https://dbafromthecold.wordpress.com/2014/10/01/identifying-large-queries-using-extended-events/
USE [master];
GO
 
CREATE EVENT SESSION [ExpensiveQueries] ON SERVER 
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.client_hostname,sqlserver.database_name,sqlserver.session_id,sqlserver.sql_text,sqlserver.tsql_stack,sqlserver.username)
    WHERE ([logical_reads]>10000))
ADD TARGET package0.event_file(SET filename=N'C:\Temp\ExpensiveQueries.xel')
GO

ALTER EVENT SESSION [ExpensiveQueries]
ON SERVER
STATE = START;
GO

SELECT COUNT(*)
FROM sys.fn_xe_file_target_read_file
 ('C:\Temp\ExpensiveQueries*.xel',NULL,NULL,NULL);
GO

WITH CTE_ExecutedSQLStatements AS
(SELECT 
    [XML Data],
	[XML Data].value('(/event/action[@name=''database_name'']/value)[1]','varchar(max)')        AS [Database Name],
	[XML Data].value('(/event/action[@name=''client_hostname'']/value)[1]','varchar(max)')      AS [Client Hostname],
    [XML Data].value('(/event[@name=''sql_statement_completed'']/@timestamp)[1]','DATETIME')    AS [Time],
    [XML Data].value('(/event/data[@name=''duration'']/value)[1]','int')                        AS [Duration],
    [XML Data].value('(/event/data[@name=''cpu_time'']/value)[1]','int')                        AS [CPU],
    [XML Data].value('(/event/data[@name=''logical_reads'']/value)[1]','int')                   AS [logical_reads],
    [XML Data].value('(/event/data[@name=''physical_reads'']/value)[1]','int')                  AS [physical_reads],
	[XML Data].value('(/event/action[@name=''sql_text'']/value)[1]','varchar(max)')             AS [SQL Statement]
    --[XML Data].value('(/event/data[@name=''statement'']/value)[1]','varchar(max)')              AS [SQL Statement]
FROM
    (SELECT
        object_name              AS [Event], 
        CONVERT(XML, event_data) AS [XML Data]
    FROM
        sys.fn_xe_file_target_read_file
    ('C:\Temp\ExpensiveQueries*.xel',NULL,NULL,NULL)) as v)
SELECT
	[Database Name]			AS [Database Name],
	[Client Hostname]		AS [Client Hostname],
    [SQL Statement]			AS [SQL Statement],
    SUM(Duration)			AS [Total Duration],
    SUM(CPU)				AS [Total CPU],
    SUM(logical_reads)		AS [Total Logical Reads],
    AVG(logical_reads)		AS [Average Logical Reads],
	COUNT(logical_reads)	AS [Number of Statements],
    SUM(physical_reads)		AS [Total Physical Reads]
FROM
    CTE_ExecutedSQLStatements
GROUP BY
    [Database Name], [Client Hostname], [SQL Statement]
ORDER BY
    [Total Logical Reads] DESC
GO
