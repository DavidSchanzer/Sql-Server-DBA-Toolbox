EXEC dbo.sp_foreachdb @command = 'ALTER DATABASE ? SET OFFLINE',
                      @user_only = 1;
