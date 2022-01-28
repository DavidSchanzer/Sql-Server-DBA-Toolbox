-- Reduce VLF count
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script reduces the number of VLFs in the current database's transaction log by shrinking and then regrowing it to its original size.
-- From: http://adventuresinsql.com/2009/12/a-busyaccidental-dbas-guide-to-managing-vlfs/

USE <DatabaseName> --Set db name before running using drop-down above or this USE statement
GO

DECLARE @file_name sysname,
        @file_size INT,
        @shrink_command NVARCHAR(MAX),
        @alter_command NVARCHAR(MAX);

SELECT @file_name = name,
       @file_size = (size / 128)
FROM sys.database_files
WHERE type_desc = 'log';

SELECT @shrink_command = N'DBCC SHRINKFILE (N''' + @file_name + N''' , 0, TRUNCATEONLY)';
PRINT @shrink_command;
EXEC sys.sp_executesql @stmt = @shrink_command;

SELECT @shrink_command = N'DBCC SHRINKFILE (N''' + @file_name + N''' , 0)';
PRINT @shrink_command;
EXEC sys.sp_executesql @stmt = @shrink_command;

SELECT @alter_command
    = N'ALTER DATABASE [' + DB_NAME() + N'] MODIFY FILE (NAME = N''' + @file_name + N''', SIZE = '
      + CAST(@file_size AS NVARCHAR) + N'MB)';
PRINT @alter_command;
EXEC sys.sp_executesql @stmt = @alter_command;
GO
