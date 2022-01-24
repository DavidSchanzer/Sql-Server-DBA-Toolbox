-- Monitoring Errors with Extended Events
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script creates an Extended Events session called "exErrors" that includes the error_reported event.
-- From "How to Use SQL Server’s Extended Events and Notifications to Proactively Resolve Performance Issues" by Jason Strate (Quest Software)
--
-- The errors that appear in the error log aren’t the only ones you will care about as a DBA. Although we aren’t always the ones writing applications in
-- our environments, we do bear the responsibility of knowing when applications fail and why. For these responsibilities, the extended events platform
-- provides the flexibility and depth needed to gather information on errors in SQL Server. In the context of errors, we are talking about errors that
-- users will often see but that don’t end up in the error log, such as the error message "could not find stored procedure":
-- Msg 2812, Level 16, State 62, Line 2
-- Could not find stored procedure 'asdfasdf'.
--
-- While this and similar errors are part of the applications that use SQL Server, some applications lack the error handling necessary to properly
-- communicate the issue to the end-user or developer. Sometimes, when the errors bubble up, the context of the error message is lost along with
-- important details regarding the error.
--
-- Extended events can provide a lightweight tracing platform to collect errors as they occur, providing the DBA with a chance to review recent error
-- messages and assist developers with troubleshooting issues. It’s also a way to keep a pulse on issues that could become larger in the future.
--
-- These details will provide the information needed to take an error and track it down to an application to fix the issues that are being encountered.
-- The extended event session for this can be created with the following script.

CREATE EVENT SESSION [exErrors]
ON SERVER
    ADD EVENT sqlserver.error_reported
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_id,
         sqlserver.session_id,
         sqlserver.sql_text,
         sqlserver.username
     )
     WHERE (
               [error_number] = (18452)
               OR [error_number] = (17806)
           )
    )
    ADD TARGET package0.event_file
    (SET filename = N'c:\temp\exErrors')
WITH
(
    MAX_MEMORY = 4096KB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY = 5 SECONDS,
    MAX_EVENT_SIZE = 0KB,
    MEMORY_PARTITION_MODE = NONE,
    TRACK_CAUSALITY = ON,
    STARTUP_STATE = OFF
);
GO

ALTER EVENT SESSION exErrors ON SERVER STATE = START;
GO
;

--When errors have occurred that the event session is capturing, they can be read through a query similar to this:
WITH exErrors
AS (SELECT CAST(st.target_data AS XML) AS SessionData
    FROM sys.dm_xe_session_targets AS st
        INNER JOIN sys.dm_xe_sessions AS s
            ON s.address = st.event_session_address
    WHERE s.name = 'exErrors')
SELECT error.value('(@timestamp)[1]', 'datetime') AS event_timestamp,
       error.value('(data/value)[1]', 'int') AS error_number,
       error.value('(data/value)[2]', 'int') AS severity,
       error.value('(data/value)[3]', 'int') AS state,
       error.value('(data/value)[4]', 'bit') AS user_defined,
       error.value('(data/text)[5]', 'nvarchar(255)') AS category,
       error.value('(data/text)[6]', 'nvarchar(255)') AS destination,
       error.value('(data/value)[7]', 'bit') AS is_intercepted, -- Indicates whether the error was intercepted by a Transact-SQL TRY/CATCH block.
       error.value('(data/value)[8]', 'nvarchar(max)') AS message,
       error.value('(action/value)[1]', 'nvarchar(255)') AS username,
       DB_NAME(error.value('(action/value)[2]', 'int')) AS database_name,
       error.value('(action/value)[3]', 'nvarchar(255)') AS client_hostname,
       error.value('(action/value)[4]', 'nvarchar(255)') AS client_app_name,
       error.value('(action/value)[6]', 'nvarchar(max)') AS sql_text,
       error.value('(action/value)[7]', 'int') AS session_id
FROM exErrors AS d
    CROSS APPLY SessionData.nodes('//RingBufferTarget/event') AS t(error)
WHERE error.value('@name', 'nvarchar(128)') = 'error_reported';

--From here, a DBA can easily begin tracking down issues and informing developers of where errors are occurring, the frequency in which they are
-- occurring, and what T-SQLstatements are causing them to occur. This example only includes a few error messages, but it can easily be expanded to cover
-- many more messages, helping to resolve other error messages you may encounter such as truncation errors.
