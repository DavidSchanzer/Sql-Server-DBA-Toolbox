-- Find non-zero fill factors
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script finds all indexes that have a fill factor that is neither 0 nor 100

EXEC dbo.sp_ineachdb @command = '
SELECT ''?'' AS DatabaseName,
       OBJECT_NAME(object_id) AS TableName,
       name AS IndexName,
       fill_factor
FROM sys.indexes
WHERE fill_factor <> 0 AND fill_factor <> 100;
',
                     @user_only = 1;
