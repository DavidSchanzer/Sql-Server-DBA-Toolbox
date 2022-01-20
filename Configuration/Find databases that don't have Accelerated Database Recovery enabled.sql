-- Find databases that don't have Accelerated Database Recovery enabled
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists databases (on instances that are SQL Server 2019 or higher) that don't have Accelerated Database Recovery enabled

IF CONVERT(VARCHAR(2), SERVERPROPERTY('productversion')) >= '15'
BEGIN
    SELECT name
    FROM sys.databases
    WHERE database_id > 4
          AND name NOT LIKE 'ReportServer%'
          AND is_accelerated_database_recovery_on = 0;
END;
