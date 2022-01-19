-- Find LogicalNames that differ from DatabaseNames
USE master;
GO

WITH Files
AS (SELECT DB_NAME(database_id) AS DatabaseName,
           type_desc AS FileType,
           name AS LogicalName,
           physical_name AS PhysicalName
    FROM sys.master_files
    WHERE database_id > 4)
SELECT Files.DatabaseName,
       Files.FileType,
       Files.LogicalName,
       Files.PhysicalName,
       CASE
           WHEN Files.FileType = 'ROWS' THEN
               'USE [' + DatabaseName + '];ALTER DATABASE [' + DatabaseName + '] MODIFY FILE (NAME=N''' + LogicalName
               + ''', NEWNAME=N''' + DatabaseName + ''')'
           ELSE
               'USE [' + DatabaseName + '];ALTER DATABASE [' + DatabaseName + '] MODIFY FILE (NAME=N''' + LogicalName
               + ''', NEWNAME=N''' + DatabaseName + '_log'')'
       END AS Command
FROM Files
WHERE Files.DatabaseName <> 'SSISDB'
      AND Files.DatabaseName NOT LIKE 'ReportServer%'
      AND CHARINDEX(Files.DatabaseName, Files.LogicalName) = 0;
GO
