-- Capture all SQL and Stored Proc calls
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script creates an Extended Events session called "CaptureAllSQLAndStoredProcCalls" that includes the following events:
--		error_reported (for severity 20 and above, as well as certain error numbers)
--		existing_connection
--		login
--		logout
--		rpc_completed
--		sql_batch_completed

CREATE EVENT SESSION [CaptureAllSQLAndStoredProcCalls]
ON SERVER
    ADD EVENT sqlserver.error_reported
    (ACTION
     (
         package0.callstack,
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.nt_username,
         sqlserver.session_id,
         sqlserver.session_nt_username,
         sqlserver.sql_text,
         sqlserver.tsql_stack,
         sqlserver.username
     )
     WHERE (
               [severity] >= (20)
               OR
               (
                   [error_number] = (17803)
                   OR [error_number] = (701)
                   OR [error_number] = (802)
                   OR [error_number] = (8645)
                   OR [error_number] = (8651)
                   OR [error_number] = (8657)
                   OR [error_number] = (8902)
                   OR [error_number] = (41354)
                   OR [error_number] = (41355)
                   OR [error_number] = (41367)
                   OR [error_number] = (41384)
                   OR [error_number] = (41336)
                   OR [error_number] = (41309)
                   OR [error_number] = (41312)
                   OR [error_number] = (41313)
               )
           )
    ),
    ADD EVENT sqlserver.existing_connection
    (ACTION
     (
         package0.event_sequence,
         sqlserver.client_hostname,
         sqlserver.session_id
     )
    ),
    ADD EVENT sqlserver.login
    (SET collect_options_text = (1)
     ACTION
     (
         package0.event_sequence,
         sqlserver.client_hostname,
         sqlserver.session_id
     )
    ),
    ADD EVENT sqlserver.logout
    (ACTION
     (
         package0.event_sequence,
         sqlserver.session_id
     )
    ),
    ADD EVENT sqlserver.rpc_completed
    (SET collect_statement = (1)
     ACTION
     (
         package0.event_sequence,
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.nt_username,
         sqlserver.session_id,
         sqlserver.session_nt_username,
         sqlserver.sql_text,
         sqlserver.tsql_stack,
         sqlserver.username
     )
     WHERE ([package0].[equal_boolean]([sqlserver].[is_system], (0)))
    ),
    ADD EVENT sqlserver.sql_batch_completed
    (ACTION
     (
         package0.event_sequence,
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.nt_username,
         sqlserver.session_id,
         sqlserver.session_nt_username,
         sqlserver.sql_text,
         sqlserver.tsql_stack,
         sqlserver.username
     )
     WHERE ([package0].[equal_boolean]([sqlserver].[is_system], (0)))
    )
    ADD TARGET package0.event_file
    (SET filename = N'c:\temp\CaptureAllSQLAndStoredProcCalls.xel')
WITH
(
    MAX_MEMORY = 16384KB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY = 5 SECONDS,
    MAX_EVENT_SIZE = 0KB,
    MEMORY_PARTITION_MODE = PER_CPU,
    TRACK_CAUSALITY = ON,
    STARTUP_STATE = OFF
);
GO
