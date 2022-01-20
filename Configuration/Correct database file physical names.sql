-- Correct database file physical names
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists database physical names that differ from their database name

USE master;
GO

WITH Files
AS (SELECT DB_NAME(database_id) AS DatabaseName,
           type_desc AS FileType,
           name AS LogicalName,
           physical_name AS PhysicalName
    FROM sys.master_files
    WHERE database_id > 4
	AND file_id IN (1,2))
-- Turn on xp_cmdshell
SELECT Files.DatabaseName,
       Files.FileType,
       Files.LogicalName,
       Files.PhysicalName,
       CASE
           WHEN Files.FileType = 'ROWS' THEN
               'ALTER DATABASE [' + Files.DatabaseName + '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; ALTER DATABASE ['
               + Files.DatabaseName + '] SET OFFLINE; --Now rename ' + Files.PhysicalName + ' to ' + Files.DatabaseName
               + '.mdf; ALTER DATABASE [' + Files.DatabaseName + '] MODIFY FILE ( NAME = [' + Files.LogicalName
               + '], FILENAME = ''' + Files.PhysicalName + ''' ) --change to ' + Files.DatabaseName
               + '.mdf; ALTER DATABASE [' + Files.DatabaseName + '] SET ONLINE; ALTER DATABASE [' + Files.DatabaseName
               + '] SET MULTI_USER;'
           ELSE
               'ALTER DATABASE [' + Files.DatabaseName + '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; ALTER DATABASE ['
               + Files.DatabaseName + '] SET OFFLINE; --Now rename ' + Files.PhysicalName + ' to ' + Files.DatabaseName
               + '_log.ldf; ALTER DATABASE [' + Files.DatabaseName + '] MODIFY FILE ( NAME = [' + Files.LogicalName
               + '], FILENAME = ''' + Files.PhysicalName + ''' ) --change to ' + Files.DatabaseName
               + '_log.ldf; ALTER DATABASE [' + Files.DatabaseName + '] SET ONLINE; ALTER DATABASE ['
               + Files.DatabaseName + '] SET MULTI_USER;'
       END AS Command
FROM Files
WHERE Files.DatabaseName NOT LIKE 'ReportServer%'
      AND CHARINDEX(Files.DatabaseName, Files.PhysicalName) = 0;
GO
