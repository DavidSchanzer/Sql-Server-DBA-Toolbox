-- From: http://adventuresinsql.com/2009/12/a-busyaccidental-dbas-guide-to-managing-vlfs/

USE SectraHealthcareStorage --Set db name before running using drop-down above or this USE statement
GO

DECLARE @file_name sysname,
@file_size int,
@file_growth int,
@shrink_command nvarchar(max),
@alter_command nvarchar(max)

SELECT @file_name = name,
@file_size = (size / 128)
FROM sys.database_files
WHERE type_desc = 'log'

SELECT @shrink_command = 'DBCC SHRINKFILE (N''' + @file_name + ''' , 0, TRUNCATEONLY)'
PRINT @shrink_command
EXEC sp_executesql @shrink_command

SELECT @shrink_command = 'DBCC SHRINKFILE (N''' + @file_name + ''' , 0)'
PRINT @shrink_command
EXEC sp_executesql @shrink_command

SELECT @alter_command = 'ALTER DATABASE [' + db_name() + '] MODIFY FILE (NAME = N''' + @file_name + ''', SIZE = ' + CAST(@file_size AS nvarchar) + 'MB)'
PRINT @alter_command
EXEC sp_executesql @alter_command
GO
