-- From: https://www.mssqltips.com/sqlservertip/5136/check-sql-server-instant-file-initialization-for-all-servers/

SELECT @@SERVERNAME AS [Server Name],
       RIGHT(@@version, LEN(@@version) - 3 - CHARINDEX(' ON ', @@VERSION)) AS [OS Info],
       LEFT(@@VERSION, CHARINDEX('-', @@VERSION) - 2) + ' ' + CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(300)) AS [SQL Server Version],
       service_account,
       instant_file_initialization_enabled
FROM sys.dm_server_services
WHERE servicename LIKE 'SQL Server (%';
