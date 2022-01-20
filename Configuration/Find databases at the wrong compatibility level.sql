-- Find databases at the wrong compatibility level
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists databases whose Compatibility Level doesn't match the instance Compatibility Level

SELECT name,
       CAST(SUBSTRING(@@version, CHARINDEX(' - ', @@version) + 3, 2) + '0' AS INTEGER) AS instance_compatibility_level,
       CAST(compatibility_level AS INTEGER) AS database_compatibility_level
FROM sys.databases
WHERE CAST(compatibility_level AS INTEGER) <> CAST(SUBSTRING(@@version, CHARINDEX(' - ', @@version) + 3, 2) + '0' AS INTEGER);
