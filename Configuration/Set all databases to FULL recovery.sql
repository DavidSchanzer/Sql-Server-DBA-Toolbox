-- Set all databases to FULL recovery
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script generates SQL to set the Recovery Model to Full for all non-system databases

SELECT name AS DatabaseName,
       recovery_model_desc AS RecoveryModel,
       'ALTER DATABASE [' + name + '] SET RECOVERY FULL;' AS SQL
FROM sys.databases
WHERE recovery_model_desc <> 'FULL'
AND database_id > 4
ORDER BY DatabaseName;
