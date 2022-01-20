-- Set all databases to have Automatic Tuning with Force Last Good Plan turned on
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script sets the AUTOMATIC_TUNING property to ON (only valid on Enterprise Edition for SQL Server 2017 or later)

EXEC dbo.sp_ineachdb @command = 'ALTER DATABASE ? SET AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN = ON )',
                     @user_only = 1;
