-- Extended Events session DurationOver500ms
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script creates an Extended Events session called "DurationOver500ms" that rpc_completed and sql_batch_completed with more than 500ms duration.
-- It then starts the EE session and shreds the XML results after collecting data for 10 mins (and only for the first 1000 rows).
-- From https://simplesqlserver.com/2015/10/26/extended-events-intro/

-- Check whether the Extended Events session already exists, and drop it if it does
IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = 'DurationOver500ms')
	DROP EVENT SESSION [DurationOver500ms] ON SERVER;
GO

-- Check whether the Extended Events session already exists
CREATE EVENT SESSION [DurationOver500ms]
ON SERVER
ADD EVENT sqlserver.rpc_completed(
	ACTION 
	(
		  sqlserver.client_app_name			-- ApplicationName from SQLTrace
		, sqlserver.client_hostname			-- HostName from SQLTrace
		, sqlserver.client_pid				-- ClientProcessID from SQLTrace
		, sqlserver.database_id				-- DatabaseID from SQLTrace
		, sqlserver.request_id				-- RequestID from SQLTrace
		, sqlserver.server_principal_name	-- LoginName from SQLTrace
		, sqlserver.session_id				-- SPID from SQLTrace
	)
	WHERE 
	(
			duration >= 500000
	)
),
ADD EVENT sqlserver.sql_batch_completed(
	ACTION 
	(
		  sqlserver.client_app_name			-- ApplicationName from SQLTrace
		, sqlserver.client_hostname			-- HostName from SQLTrace
		, sqlserver.client_pid				-- ClientProcessID from SQLTrace
		, sqlserver.database_id				-- DatabaseID from SQLTrace
		, sqlserver.request_id				-- RequestID from SQLTrace
		, sqlserver.server_principal_name	-- LoginName from SQLTrace
		, sqlserver.session_id				-- SPID from SQLTrace
	)
	WHERE 
	(
		duration >= 500000
	)
)
ADD TARGET package0.event_file
(
	SET filename = 'DurationOver500ms.xel',
		max_file_size = 10,
		max_rollover_files = 5
)
WITH 
(
	MAX_MEMORY = 10MB
	, MAX_EVENT_SIZE = 10MB
	, STARTUP_STATE = ON
	, MAX_DISPATCH_LATENCY = 5 SECONDS
	, EVENT_RETENTION_MODE = ALLOW_MULTIPLE_EVENT_LOSS
);
GO

-- Start the EE session
ALTER EVENT SESSION DurationOver500ms
ON SERVER
STATE = START;
GO

-- Allow it to collect events for 10 minutes
WAITFOR DELAY '00:10:00'
GO

-- Now display the results
DECLARE @SessionName sysname = 'DurationOver500ms',
		@TopCount INT = 1000;	-- Only look at the most recent 1000 records BEFORE shredding and filtering the XML, to minimise the CPU overhead

IF OBJECT_ID('tempdb..#Events') IS NOT NULL
    BEGIN
        DROP TABLE #Events;
    END;

IF OBJECT_ID('tempdb..#Queries') IS NOT NULL
    BEGIN
        DROP TABLE #Queries; 
    END;

DECLARE @Target_File NVARCHAR(1000),
		@Target_Dir NVARCHAR(1000),
		@Target_File_WildCard NVARCHAR(1000);

SELECT  @Target_File = CAST(t.target_data AS XML).value('EventFileTarget[1]/File[1]/@name', 'NVARCHAR(256)')
FROM    sys.dm_xe_session_targets t
        INNER JOIN sys.dm_xe_sessions s ON s.address = t.event_session_address
WHERE   s.name = @SessionName
        AND t.target_name = 'event_file';
SELECT  @Target_File

SELECT  @Target_Dir = LEFT(@Target_File, LEN(@Target_File) - CHARINDEX('\', REVERSE(@Target_File))); 

SELECT  @Target_File_WildCard = @Target_Dir + '\' + @SessionName + '_*.xel';

SELECT TOP ( @TopCount )
        CAST(event_data AS XML) AS event_data_XML
INTO    #Events
FROM    sys.fn_xe_file_target_read_file(@Target_File_WildCard, NULL, NULL, NULL) AS F
ORDER BY file_name DESC ,
        file_offset DESC; 

SELECT  EventType = event_data_XML.value('(event/@name)[1]', 'varchar(50)') ,
        Duration_sec = CAST(event_data_XML.value('(/event/data[@name=''duration'']/value)[1]', 'BIGINT')
        / CASE WHEN event_data_XML.value('(event/@name)[1]', 'varchar(50)') LIKE 'wait%' THEN 1000.0
               ELSE 1000000.0
          END AS DEC(20, 3)) ,
        CPU_sec = CAST(event_data_XML.value('(/event/data[@name=''cpu_time'']/value)[1]', 'BIGINT') / 1000000.0 AS DEC(20, 3)) ,
        physical_reads_k = CAST(event_data_XML.value('(/event/data  [@name=''physical_reads'']/value)[1]', 'BIGINT') / 1000.0 AS DEC(20, 3)) ,
        logical_reads_k = CAST(event_data_XML.value('(/event/data  [@name=''logical_reads'']/value)[1]', 'BIGINT') / 1000.0 AS DEC(20, 3)) ,
        writes_k = CAST(event_data_XML.value('(/event/data  [@name=''writes'']/value)[1]', 'BIGINT') / 1000.0 AS DEC(20, 3)) ,
        row_count = event_data_XML.value('(/event/data  [@name=''row_count'']/value)[1]', 'BIGINT') ,
        Statement_Text = ISNULL(event_data_XML.value('(/event/data  [@name=''statement'']/value)[1]', 'NVARCHAR(4000)'),
                                event_data_XML.value('(/event/data  [@name=''batch_text''     ]/value)[1]', 'NVARCHAR(4000)')) ,
        TimeStamp = DATEADD(HOUR, DATEDIFF(HOUR, GETUTCDATE(), GETDATE()), CAST(event_data_XML.value('(event/@timestamp)[1]', 'varchar(50)') AS DATETIME2)) ,
        SPID = event_data_XML.value('(/event/action  [@name=''session_id'']/value)[1]', 'BIGINT') ,
        Username = event_data_XML.value('(/event/action  [@name=''server_principal_name'']/value)[1]', 'NVARCHAR(256)') ,
        Database_Name = DB_NAME(event_data_XML.value('(/event/action  [@name=''database_id'']/value)[1]', 'BIGINT')) ,
        client_app_name = event_data_XML.value('(/event/action  [@name=''client_app_name'']/value)[1]', 'NVARCHAR(256)') ,
        client_hostname = event_data_XML.value('(/event/action  [@name=''client_hostname'']/value)[1]', 'NVARCHAR(256)') ,
        result = ISNULL(event_data_XML.value('(/event/data  [@name=''result'']/text)[1]', 'NVARCHAR(256)'),
                        event_data_XML.value('(/event/data  [@name=''message'']/value)[1]', 'NVARCHAR(256)')) ,
        Error = event_data_XML.value('(/event/data  [@name=''error_number'']/value)[1]', 'BIGINT') ,
        Severity = event_data_XML.value('(/event/data  [@name=''severity'']/value)[1]', 'BIGINT') ,
        EventDetails = event_data_XML
INTO    #Queries
FROM    #Events;

SELECT  q.EventType ,
        q.Duration_sec ,
        q.CPU_sec ,
        q.physical_reads_k ,
        q.logical_reads_k ,
        q.writes_k ,
        q.row_count ,
        q.Statement_Text ,
        q.TimeStamp ,
        q.SPID ,
        q.Username ,
        q.Database_Name ,
        client_app_name = CASE LEFT(q.client_app_name, 29)
                            WHEN 'SQLAgent - TSQL JobStep (Job '
                            THEN 'SQLAgent Job: ' + ( SELECT    name COLLATE DATABASE_DEFAULT
                                                      FROM      msdb..sysjobs sj
                                                      WHERE     SUBSTRING(q.client_app_name, 32, 32) = ( SUBSTRING(sys.fn_varbintohexstr(sj.job_id), 3, 100) )
                                                    ) + ' - ' + SUBSTRING(q.client_app_name, 67, LEN(q.client_app_name) - 67)
                            ELSE q.client_app_name
                          END ,
        q.client_hostname ,
        q.result ,
        q.Error ,
        q.Severity ,
        q.EventDetails
FROM    #Queries q
ORDER BY TimeStamp DESC; 
GO

-- Stop the EE session
ALTER EVENT SESSION DurationOver500ms
ON SERVER
STATE = STOP;
GO
