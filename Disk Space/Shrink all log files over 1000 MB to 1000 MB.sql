EXEC sp_ineachdb @user_only = 1, @command = N'
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
';
