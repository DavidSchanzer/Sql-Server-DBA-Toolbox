-- Capture all unencrypted database connections using a Logon trigger
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script creates a Logon trigger that records into table tempdb.dbo.unencrypted_connections any unencrypted T-SQL TCP database connections except for those from SSMS.
-- Some applications make very frequent and multiple database connections, so actively monitor the number of rows being inserted into this table to avoid filling TempDB.

DROP TABLE IF EXISTS tempdb.dbo.unencrypted_connections;
GO

SELECT DB_NAME(s.database_id) AS database_name,
       s.original_login_name,
       C.session_id,
       C.connect_time,
       C.encrypt_option,
       C.client_net_address,
       s.login_time,
       s.host_name,
       s.program_name,
       s.host_process_id,
       s.client_interface_name,
       s.status
INTO tempdb.dbo.unencrypted_connections
FROM sys.dm_exec_connections AS C
    LEFT OUTER JOIN sys.dm_exec_sessions AS s
        ON s.session_id = C.session_id
WHERE 1 = 0;
GO

DROP TRIGGER IF EXISTS connection_encrypt
ON ALL SERVER;
GO

CREATE TRIGGER connection_encrypt
ON ALL SERVER
WITH EXECUTE AS N'sa'
FOR LOGON
AS
BEGIN
    INSERT INTO tempdb.dbo.unencrypted_connections
    (
        database_name,
        original_login_name,
        session_id,
        connect_time,
        encrypt_option,
        client_net_address,
        login_time,
        host_name,
        program_name,
        host_process_id,
        client_interface_name,
        status
    )
    SELECT DB_NAME(s.database_id),
           s.original_login_name,
           C.session_id,
           C.connect_time,
           C.encrypt_option,
           C.client_net_address,
           s.login_time,
           s.host_name,
           s.program_name,
           s.host_process_id,
           s.client_interface_name,
           s.status
    FROM sys.dm_exec_connections AS C
        LEFT OUTER JOIN sys.dm_exec_sessions AS s
            ON s.session_id = C.session_id
    WHERE C.session_id = @@spid
          AND C.encrypt_option = 'FALSE'
          AND C.protocol_type = 'TSQL'
          AND C.net_transport = 'TCP'
          AND s.program_name NOT LIKE 'Microsoft SQL Server Management Studio%';
END;
GO
