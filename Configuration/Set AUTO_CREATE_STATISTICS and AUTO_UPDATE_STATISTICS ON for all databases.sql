SELECT 'ALTER DATABASE [' + name + '] SET AUTO_CREATE_STATISTICS ON;'
FROM sys.databases
WHERE is_auto_create_stats_on = 0;
SELECT 'ALTER DATABASE [' + name + '] SET AUTO_UPDATE_STATISTICS ON;'
FROM sys.databases
WHERE is_auto_update_stats_on = 0;
