-- Track calls to a stored procedure using a wildcard
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script creates an Extended Events session called "TrackSPCallsWithWildcard" that uses the exec_prepared_sql, prepare_sql, rpc_completed,
-- sp_statement_completed, sql_batch_completed and unprepare_sql events to track usage of a nominated stored procedure.
-- It then starts the EE session, collects data for 2 hours and shreds the XML data collected.

-- Stop trace if started
IF EXISTS
(
    SELECT *
    FROM sys.dm_xe_sessions
    WHERE name = 'TrackSPCallsWithWildcard'
)
    ALTER EVENT SESSION TrackSPCallsWithWildcard ON SERVER STATE = STOP;

-- Delete trace if exists
IF EXISTS
(
    SELECT *
    FROM sys.server_event_sessions
    WHERE name = 'TrackSPCallsWithWildcard'
)
    DROP EVENT SESSION TrackSPCallsWithWildcard ON SERVER;

-- Create trace
CREATE EVENT SESSION TrackSPCallsWithWildcard
ON SERVER
    ADD EVENT sqlserver.exec_prepared_sql
    (ACTION
     (
         sqlserver.sql_text
     )
     WHERE (
               ([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name], N'<DatabaseName>'))
               AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text], N'%<StoredProcName>%'))
           )
    ),
    ADD EVENT sqlserver.prepare_sql
    (ACTION
     (
         sqlserver.sql_text
     )
     WHERE (
               ([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name], N'<DatabaseName>'))
               AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text], N'%<StoredProcName>%'))
           )
    ),
    ADD EVENT sqlserver.rpc_completed
    (ACTION
     (
         sqlserver.sql_text
     )
     WHERE (
               ([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name], N'<DatabaseName>'))
               AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text], N'%<StoredProcName>%'))
           )
    ),
    ADD EVENT sqlserver.sp_statement_completed
    (ACTION
     (
         sqlserver.sql_text
     )
     WHERE (
               ([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name], N'<DatabaseName>'))
               AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text], N'%<StoredProcName>%'))
           )
    ),
    ADD EVENT sqlserver.sql_batch_completed
    (ACTION
     (
         sqlserver.sql_text
     )
     WHERE (
               ([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name], N'<DatabaseName>'))
               AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text], N'%<StoredProcName>%'))
           )
    ),
    ADD EVENT sqlserver.unprepare_sql
    (ACTION
     (
         sqlserver.sql_text
     )
     WHERE (
               ([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name], N'<DatabaseName>'))
               AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text], N'%<StoredProcName>%'))
           )
    )
    ADD TARGET package0.event_file
    (SET filename = N'c:\temp\TrackSPCallsWithWildcard.xel')
WITH
(
    TRACK_CAUSALITY = ON
);
GO

-- Start EE session
ALTER EVENT SESSION TrackSPCallsWithWildcard ON SERVER STATE = START;

-- Allow it to collect events for 2 hours
WAITFOR DELAY '02:00:00';
GO

-- Now display the results
DECLARE @SessionName sysname = 'TrackSPCallsWithWildcard';

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
ORDER BY file_name DESC,
         F.file_offset DESC;

SELECT event_data_XML.value('(event/@name)[1]', 'varchar(50)') AS name,
       DATEADD(
                  HOUR,
                  DATEDIFF(HOUR, GETUTCDATE(), GETDATE()),
                  CAST(event_data_XML.value('(event/@timestamp)[1]', 'varchar(50)') AS DATETIME2)
              ) AS timestamp,
       event_data_XML.value('(/event/data  [@name=''object_type'']/text)[1]', 'NVARCHAR(256)') AS object_type,
       event_data_XML.value('(/event/data  [@name=''line_number'']/value)[1]', 'NVARCHAR(256)') AS line_number,
       event_data_XML.value('(/event/data  [@name=''object_name'']/value)[1]', 'NVARCHAR(256)') AS object_name,
       event_data_XML.value('(/event/data  [@name=''statement'']/value)[1]', 'NVARCHAR(4000)') AS statement,
       event_data_XML.value('(/event/action  [@name=''sql_text'']/value)[1]', 'NVARCHAR(4000)') AS sql_text,
       event_data_XML.value('(/event/action  [@name=''attach_activity_id'']/value)[1]', 'NVARCHAR(256)') AS attach_activity_id,
       event_data_XML AS EventDetails
INTO #Queries
FROM #Events;

SELECT q.[name],
       q.timestamp,
       q.object_type,
       q.line_number,
       q.object_name,
       q.statement,
       q.sql_text,
       q.attach_activity_id,
       LEFT(q.attach_activity_id, LEN(q.attach_activity_id) - CHARINDEX('-', REVERSE(q.attach_activity_id))) AS [attach_activity_id.guid],
       CAST(RIGHT(q.attach_activity_id, CHARINDEX('-', REVERSE(q.attach_activity_id)) - 1) AS INT) AS [attach_activity_id.seq],
       q.EventDetails
FROM #Queries AS q
ORDER BY q.timestamp,
         CAST(RIGHT(q.attach_activity_id, CHARINDEX('-', REVERSE(q.attach_activity_id)) - 1) AS INT);
GO

-- Stop the EE session
ALTER EVENT SESSION TrackSPCallsWithWildcard ON SERVER STATE = STOP;
GO
