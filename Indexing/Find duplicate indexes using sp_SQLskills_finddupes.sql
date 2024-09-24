-- Find duplicate indexes using sp_SQLskills_finddupes
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script calls the SQL Skills duplicate index finder stored procedure sp_SQLskills_finddupes for every user database

USE master;
GO

EXEC dbo.sp_ineachdb @command = 'EXEC dbo.sp_SQLskills_finddupes',
                     @user_only = 1;
GO
