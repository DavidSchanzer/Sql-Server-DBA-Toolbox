EXEC dbo.sp_ineachdb 'ALTER DATABASE ? SET AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN = ON )',
                     @user_only = 1;
