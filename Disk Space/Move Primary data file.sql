CREATE DATABASE [test]
ON PRIMARY
       (
           NAME = N'test1',
           FILENAME = N'C:\SQL2016_CI_AS\Data\test1.mdf',
           SIZE = 8192KB,
           FILEGROWTH = 65536KB
       )
LOG ON
    (
        NAME = N'test_log',
        FILENAME = N'C:\SQL2016_CI_AS\Data\test_log.ldf',
        SIZE = 8192KB,
        FILEGROWTH = 65536KB
    );
GO

USE [test];
GO

CREATE TABLE [Test_Data]
(
    [Id] INT IDENTITY,
    [Date] DATETIME
        DEFAULT GETDATE(),
    [City] CHAR(25)
        DEFAULT 'Sydney',
    [Name] CHAR(25)
        DEFAULT 'John Smith'
);
GO

-- Insert a million rows
INSERT INTO Test_Data
DEFAULT VALUES;
GO 1000000

SELECT DB_NAME() AS [DatabaseName],
       name,
       file_id,
       physical_name,
       (size * 8.0 / 1024) AS Size,
       ((size * 8.0 / 1024) - (FILEPROPERTY(name, 'SpaceUsed') * 8.0 / 1024)) AS FreeSpace
FROM sys.database_files
WHERE type_desc = 'ROWS'
ORDER BY name;
GO

-- Now create a second data file in the new location
ALTER DATABASE [test]
ADD FILE
    (
        NAME = test2,
        FILENAME = 'C:\Temp\test2.ndf',
        SIZE = 8192KB
    );
GO

-- Insert another million rows
INSERT INTO Test_Data
DEFAULT VALUES;
GO 1000000

SELECT DB_NAME() AS [DatabaseName],
       name,
       file_id,
       physical_name,
       (size * 8.0 / 1024) AS Size,
       ((size * 8.0 / 1024) - (FILEPROPERTY(name, 'SpaceUsed') * 8.0 / 1024)) AS FreeSpace
FROM sys.database_files
WHERE type_desc = 'ROWS'
ORDER BY name;
GO

-- Now try to empty the first file
DBCC SHRINKFILE('test1', EMPTYFILE);
GO
-- This throws the error:
--		Msg 2555, Level 16, State 1, Line 57
--		Cannot move all contents of file "test1" to other places to complete the emptyfile operation.

-- However, the following statement makes the file as small as possible.
DBCC SHRINKFILE (N'test1' , 1)
GO

SELECT DB_NAME() AS [DatabaseName],
       name,
       file_id,
       physical_name,
       (size * 8.0 / 1024) AS Size,
       ((size * 8.0 / 1024) - (FILEPROPERTY(name, 'SpaceUsed') * 8.0 / 1024)) AS FreeSpace
FROM sys.database_files
WHERE type_desc = 'ROWS'
ORDER BY name;
GO

-- Take database offline
USE master;
GO
ALTER DATABASE [test] SET OFFLINE;
GO
ALTER DATABASE [test] MODIFY FILE ( NAME = test1, FILENAME = 'C:\Temp\test1.mdf' );
GO
-- Now move the test1 files to the new location
ALTER DATABASE [test] SET ONLINE;
GO

-- Check the locations of all files
SELECT name, physical_name AS CurrentLocation, state_desc  
FROM sys.master_files  
WHERE database_id = DB_ID(N'test');
GO

-- Now empty the second file
USE [test];
GO
DBCC SHRINKFILE (N'test2', EMPTYFILE);
GO

-- Now remove the second file
ALTER DATABASE [test] REMOVE FILE test2;
GO

-- Check the locations of all files
SELECT name, physical_name AS CurrentLocation, state_desc  
FROM sys.master_files  
WHERE database_id = DB_ID(N'test');
GO

-- Check that there are still 2 million rows in the table
SELECT COUNT(*) FROM [Test_Data];
GO

USE [master];
GO
DROP DATABASE [test];
GO
