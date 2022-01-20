-- Set AUTO_CREATE_STATISTICS and AUTO_UPDATE_STATISTICS ON for all databases
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script generates SQL to set the AUTO_CREATE_STATISTICS and AUTO_UPDATE_STATISTICS properties on for all databases on which it's currently off

SELECT 'ALTER DATABASE [' + name + '] SET AUTO_CREATE_STATISTICS ON;'
FROM sys.databases
WHERE is_auto_create_stats_on = 0;

SELECT 'ALTER DATABASE [' + name + '] SET AUTO_UPDATE_STATISTICS ON;'
FROM sys.databases
WHERE is_auto_update_stats_on = 0;
