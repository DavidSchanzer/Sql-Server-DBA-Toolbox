-- All files ordered by descending free space
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists all data and log files for all databases, listed in ascending order of the percentage of free space in the file

IF OBJECT_ID('TempDB..#Temp', 'U') > 0
    DROP TABLE #Temp;

CREATE TABLE #Temp
(
    DatabaseName sysname NULL,
    Drive CHAR(1) NULL,
    FileType NVARCHAR(60) NULL,
    FileSizeMB DECIMAL(12, 2) NULL,
    SpaceUsedMB DECIMAL(12, 2) NULL,
    FreeSpaceMB DECIMAL(12, 2) NULL,
    FreeSpacePercentage DECIMAL(12, 2) NULL,
    FileID INT NULL,
    LogicalName NVARCHAR(200) NULL,
    PhysicalName NVARCHAR(200) NULL
);

INSERT INTO #Temp
(
    DatabaseName,
    Drive,
    FileType,
    FileSizeMB,
    SpaceUsedMB,
    FreeSpaceMB,
    FreeSpacePercentage,
    FileID,
    LogicalName,
    PhysicalName
)
EXEC master.dbo.sp_ineachdb @command = '
SELECT ''?'' AS DatabaseName, SUBSTRING(a.physical_name, 1, 1) Drive,
	   type_desc AS FileType,
       [FileSizeMB] = CONVERT(DECIMAL(12, 2), ROUND(a.size / 128.000, 2)),
       [SpaceUsedMB] = CONVERT(DECIMAL(12, 2), ROUND(FILEPROPERTY(a.name, ''SpaceUsed'') / 128.000, 2)),
       [FreeSpaceMB] = CONVERT(DECIMAL(12, 2), ROUND((a.size - FILEPROPERTY(a.name, ''SpaceUsed'')) / 128.000, 2)),
       FreeSpacePercentage = CONVERT(
                                   DECIMAL(12, 2),
                                   (CONVERT(
                                               DECIMAL(12, 2),
                                               ROUND((a.size - FILEPROPERTY(a.name, ''SpaceUsed'')) / 128.000, 2)
                                           ) / CONVERT(DECIMAL(12, 2), ROUND(a.size / 128.000, 2)) * 100
                                   )
                               ),
       a.file_id,
	   a.name,
       a.physical_name
FROM sys.database_files a;
', @user_only = 1;

SELECT DatabaseName,
       Drive,
       FileType,
       FileSizeMB,
       SpaceUsedMB,
       FreeSpaceMB,
       FreeSpacePercentage,
       FileID,
       LogicalName,
       PhysicalName
FROM #Temp
WHERE DatabaseName NOT IN ( 'master', 'model', 'msdb', 'tempdb' )
ORDER BY FreeSpacePercentage;

DROP TABLE #Temp;