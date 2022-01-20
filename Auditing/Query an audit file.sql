-- Query an audit file
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script returns all relevant columns from a database audit for a nominated login and date/time range
-- Values to be modified before execution:
DECLARE @DBName VARCHAR(100) = '<DatabaseName>';
DECLARE @AuditPath VARCHAR(100) = '<PathToAuditsFolder>' + '\' + @DBName;
DECLARE @LoginName NVARCHAR(128) = N'<LoginName>';
DECLARE @StartDateTime DATETIME2(7) = '<yyyy-mm-dd hh:mm>';
DECLARE @EndDateTime DATETIME2(7) = '<yyyy-mm-dd hh:mm>';

SELECT DATEADD(MINUTE, DATEDIFF(MINUTE, GETUTCDATE(), CURRENT_TIMESTAMP), event_time) AS event_time_local,
       sequence_number,
       action_id,
       succeeded,
       permission_bitmask,
       is_column_permission,
       session_id,
       server_principal_id,
       database_principal_id,
       target_server_principal_id,
       target_database_principal_id,
       object_id,
       class_type,
       session_server_principal_name,
       server_principal_name,
       server_principal_sid,
       database_principal_name,
       target_server_principal_name,
       target_server_principal_sid,
       target_database_principal_name,
       server_instance_name,
       database_name,
       schema_name,
       object_name,
       statement,
       additional_information,
       file_name,
       audit_file_offset,
       user_defined_event_id,
       user_defined_information,
       audit_schema_version,
       sequence_group_id,
       transaction_id,
       client_ip,
       application_name,
       duration_milliseconds,
       response_rows,
       affected_rows
FROM sys.fn_get_audit_file(@AuditPath + '\' + @DBName + '\*', DEFAULT, DEFAULT)
WHERE session_server_principal_name = @LoginName
      AND DATEADD(MINUTE, DATEDIFF(MINUTE, GETUTCDATE(), CURRENT_TIMESTAMP), event_time)
      BETWEEN @StartDateTime AND @EndDateTime
ORDER BY DATEADD(MINUTE, DATEDIFF(MINUTE, GETUTCDATE(), CURRENT_TIMESTAMP), event_time) ASC;
GO
