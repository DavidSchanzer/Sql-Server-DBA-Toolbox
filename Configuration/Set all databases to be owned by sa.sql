EXEC sp_ineachdb 'EXEC dbo.sp_changedbowner @loginame = N''sa'', @map = false',
                 @user_only = 1;
