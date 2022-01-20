-- Set all databases to be owned by sa
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script sets the owner of all user databases to 'sa'

EXEC dbo.sp_ineachdb @command = 'EXEC dbo.sp_changedbowner @loginame = N''sa'', @map = false',
                     @user_only = 1;
