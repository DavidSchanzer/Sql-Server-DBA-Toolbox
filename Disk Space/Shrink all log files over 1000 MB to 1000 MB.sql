-- Shrink all log files over 1000 MB to 1000 MB
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script is a quick way to make space on a drive that holds transaction log, by truncating all "tall poppies" to be a maximum of 1000 MB.

EXEC dbo.sp_ineachdb @command = N'
DECLARE @new_size_MB int = 10000,
		@curr_size_8K int,
		@sql VARCHAR(1000);
SELECT @curr_size_8K = size,
	   @sql = ''DBCC SHRINKFILE (N'''''' + name + '''''' , 10000)''
	FROM sys.database_files
	WHERE type_desc = ''LOG'';
IF @curr_size_8K * 8 / 1024 > @new_size_MB
BEGIN
	PRINT @sql;
	EXEC (@sql);
END;
',
                     @user_only = 1;
