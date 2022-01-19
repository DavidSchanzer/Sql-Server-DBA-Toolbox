-- From https://karaszi.com/looking-for-strange

--Stop trace if started
IF EXISTS
(
    SELECT *
    FROM sys.dm_xe_sessions
    WHERE name = 'LookingForUndesirableEvents'
)
    ALTER EVENT SESSION LookingForUndesirableEvents ON SERVER STATE = STOP;

--Delete trace if exists
IF EXISTS
(
    SELECT *
    FROM sys.server_event_sessions
    WHERE name = 'LookingForUndesirableEvents'
)
    DROP EVENT SESSION LookingForUndesirableEvents ON SERVER;

--Create trace
CREATE EVENT SESSION LookingForUndesirableEvents
ON SERVER
    --ADD EVENT sqlserver.attention
    --(ACTION
    -- (
    --     sqlserver.client_app_name,
    --     sqlserver.client_hostname,
    --     sqlserver.database_name,
    --     sqlserver.server_instance_name,
    --     sqlserver.server_principal_name,
    --     sqlserver.sql_text
    -- )
    --WHERE (
    --           package0.greater_than_uint64(database_id, (4))
    --           AND package0.equal_boolean(sqlserver.is_system, (0))
    --       )
    --),
    --ADD EVENT sqlserver.auto_stats
    --(ACTION
    -- (
    --     sqlserver.client_app_name,
    --     sqlserver.client_hostname,
    --     sqlserver.database_name,
    --     sqlserver.server_instance_name,
    --     sqlserver.server_principal_name,
    --     sqlserver.sql_text
    -- )
    --WHERE (
    --           package0.greater_than_uint64(database_id, (4))
    --           AND package0.equal_boolean(sqlserver.is_system, (0))
    --           AND package0.greater_than_equal_int64(object_id, (1000000))
    --           AND package0.greater_than_uint64(duration, (10))
    --       )
    --),
    ADD EVENT sqlserver.database_file_size_change
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.server_instance_name,
         sqlserver.server_principal_name,
         sqlserver.sql_text
     )),
    ADD EVENT sqlserver.database_started
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.server_instance_name,
         sqlserver.server_principal_name,
         sqlserver.sql_text
     )),
    ADD EVENT sqlserver.lock_deadlock
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.server_instance_name,
         sqlserver.server_principal_name,
         sqlserver.sql_text
     )),
    --ADD EVENT sqlserver.lock_escalation
    --(ACTION
    -- (
    --     sqlserver.client_app_name,
    --     sqlserver.client_hostname,
    --     sqlserver.database_name,
    --     sqlserver.server_instance_name,
    --     sqlserver.server_principal_name,
    --     sqlserver.sql_text
    -- )),
    ADD EVENT sqlserver.lock_timeout_greater_than_0
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.server_instance_name,
         sqlserver.server_principal_name,
         sqlserver.sql_text
     )),
    ADD EVENT sqlserver.long_io_detected
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.server_instance_name,
         sqlserver.server_principal_name,
         sqlserver.sql_text
     )),

    --Begin performance section
    ADD EVENT qds.query_store_plan_forcing_failed
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.server_instance_name,
         sqlserver.server_principal_name,
         sqlserver.sql_text
     )),
    ADD EVENT sqlserver.exchange_spill
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.server_instance_name,
         sqlserver.server_principal_name,
         sqlserver.sql_text
     )),
    ADD EVENT sqlserver.execution_warning
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.server_instance_name,
         sqlserver.server_principal_name,
         sqlserver.sql_text
     )),
    ADD EVENT sqlserver.hash_spill_details
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.server_instance_name,
         sqlserver.server_principal_name,
         sqlserver.sql_text
     )),
    ADD EVENT sqlserver.hash_warning
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.server_instance_name,
         sqlserver.server_principal_name,
         sqlserver.sql_text
     )),
    ADD EVENT sqlserver.query_memory_grant_blocking
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.server_instance_name,
         sqlserver.server_principal_name,
         sqlserver.sql_text
     )),
    ADD EVENT sqlserver.query_memory_grants
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.server_instance_name,
         sqlserver.server_principal_name,
         sqlserver.sql_text
     )),
    --ADD EVENT sqlserver.sort_warning
    --(ACTION
    -- (
    --     sqlserver.client_app_name,
    --     sqlserver.client_hostname,
    --     sqlserver.database_name,
    --     sqlserver.server_instance_name,
    --     sqlserver.server_principal_name,
    --     sqlserver.sql_text
    -- )),
    ADD EVENT sqlserver.window_spool_ondisk_warning
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.server_instance_name,
         sqlserver.server_principal_name,
         sqlserver.sql_text
     ))
    --End performance section

    ADD TARGET package0.event_file
    (SET filename = 'LookingForUndesirableEvents.xel', max_file_size = 10, max_rollover_files = 5)
WITH
(
    MAX_MEMORY = 10MB,
    MAX_EVENT_SIZE = 10MB,
    STARTUP_STATE = ON,
    MAX_DISPATCH_LATENCY = 5 SECONDS,
    EVENT_RETENTION_MODE = ALLOW_MULTIPLE_EVENT_LOSS
);
GO

--Start EE session
ALTER EVENT SESSION LookingForUndesirableEvents ON SERVER STATE = START

-- Allow it to collect events for 5 mins
WAITFOR DELAY '00:05:00'
GO

-- Now display the results
DECLARE @SessionName sysname = 'LookingForUndesirableEvents';

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

SELECT @Target_File = CAST(t.target_data AS XML).value('EventFileTarget[1]/File[1]/@name', 'NVARCHAR(256)')
FROM sys.dm_xe_session_targets AS t
    INNER JOIN sys.dm_xe_sessions AS s
        ON s.address = t.event_session_address
WHERE s.name = @SessionName
      AND t.target_name = 'event_file';
SELECT @Target_File;

SELECT @Target_Dir = LEFT(@Target_File, LEN(@Target_File) - CHARINDEX('\', REVERSE(@Target_File)));

SELECT @Target_File_WildCard = @Target_Dir + N'\' + @SessionName + N'_*.xel';

SELECT CAST(F.event_data AS XML) AS event_data_XML
INTO #Events
FROM sys.fn_xe_file_target_read_file(@Target_File_WildCard, NULL, NULL, NULL) AS F
ORDER BY file_name DESC ,
         F.file_offset DESC;

SELECT event_data_XML.value('(event/@name)[1]', 'varchar(50)') AS EventType,
       DATEADD(
                  HOUR,
                  DATEDIFF(HOUR, GETUTCDATE(), GETDATE()),
                  CAST(event_data_XML.value('(event/@timestamp)[1]', 'varchar(50)') AS DATETIME2)
              ) AS TimeStamp,
       event_data_XML.value('(/event/action  [@name=''server_principal_name'']/value)[1]', 'NVARCHAR(256)') AS Username,
       event_data_XML.value('(/event/action  [@name=''database_name'']/value)[1]', 'NVARCHAR(256)') AS Database_Name,
       event_data_XML.value('(/event/action  [@name=''client_app_name'']/value)[1]', 'NVARCHAR(256)') AS client_app_name,
	   event_data_XML.value('(/event/action  [@name=''sql_text'']/value)[1]', 'NVARCHAR(4000)') AS sql_text,
       event_data_XML.value('(/event/action  [@name=''client_hostname'']/value)[1]', 'NVARCHAR(256)') AS client_hostname,
       event_data_XML AS EventDetails
INTO #Queries
FROM #Events;

SELECT q.EventType,
       q.TimeStamp,
       q.Username,
       q.Database_Name,
       CASE LEFT(q.client_app_name, 29)
           WHEN 'SQLAgent - TSQL JobStep (Job ' THEN
               'SQLAgent Job: ' +
               (
                   SELECT sj.name COLLATE DATABASE_DEFAULT
                   FROM msdb..sysjobs AS sj
                   WHERE SUBSTRING(q.client_app_name, 32, 32) = (SUBSTRING(sys.fn_varbintohexstr(sj.job_id), 3, 100))
               ) + ' - ' + SUBSTRING(q.client_app_name, 67, LEN(q.client_app_name) - 67)
           ELSE
               q.client_app_name
       END AS client_app_name,
       q.client_hostname,
	   q.sql_text,
       q.EventDetails
FROM #Queries AS q
ORDER BY q.TimeStamp DESC;
GO


-- Stop the EE session
ALTER EVENT SESSION LookingForUndesirableEvents
ON SERVER
STATE = STOP;
GO

