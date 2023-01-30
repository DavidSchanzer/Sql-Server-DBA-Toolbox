-- Capture all failed logins
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script creates an Extended Events session called "FailedLogins" for the troubleshooting of failed login attempts.
-- From https://www.c-sharpcorner.com/blogs/find-failed-logins-using-extended-events

CREATE EVENT SESSION [FailedLogins]
ON SERVER
    ADD EVENT sqlserver.error_reported
    (ACTION
     (
         package0.callstack,
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.context_info,
         sqlserver.database_id,
         sqlserver.database_name,
         sqlserver.nt_username,
         sqlserver.sql_text,
         sqlserver.tsql_frame,
         sqlserver.tsql_stack,
         sqlserver.username
     )
     WHERE (
               [Severity] = (14)
               AND [error_number] = (18456)
               AND [State] > (1)
           )
    )
    ADD TARGET package0.event_file
    (SET filename = N'C:\temp\FailedLogins.xel')
WITH
(
    MAX_MEMORY = 4096KB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY = 30 SECONDS,
    MAX_EVENT_SIZE = 0KB,
    MEMORY_PARTITION_MODE = NONE,
    TRACK_CAUSALITY = OFF,
    STARTUP_STATE = ON
);
GO

-- Some sample code to read logged events
SELECT FailedLoginData = CONVERT(XML, event_data)
INTO #FailedLogin
FROM sys.fn_xe_file_target_read_file(N'C:\temp\FailedLogin*.xel', NULL, NULL, NULL);
SELECT EventDate = FailedLoginData.value(N'(event/@timestamp)[1]', N'datetime'),
       Message = FailedLoginData.value(N'(event/data[@name="message"]/value)[1]', N'varchar(100)')
FROM #FailedLogin
ORDER BY EventDate DESC;

DROP TABLE #FailedLogin;
GO
