EXEC sp_foreachdb 'ALTER DATABASE ? SET COMPATIBILITY_LEVEL = 140',
                  @user_only = 1;
