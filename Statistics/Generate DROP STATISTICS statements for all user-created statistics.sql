-- Generate DROP STATISTICS statements for all user-created statistics
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script returns information on each user-created statistics object, along with the DROP STATISTICS object to run if appropriate.

CREATE TABLE tempdb.dbo.UserCreatedStats
(
    [Database] sysname NOT NULL,
    SchemaName sysname NOT NULL,
    TableName sysname NOT NULL,
    StatisticsName sysname NOT NULL,
    DropStatement VARCHAR(255) NOT NULL
);

EXEC dbo.sp_ineachdb @command = '
INSERT INTO tempdb.dbo.UserCreatedStats 
SELECT DB_NAME() AS [Database], schema_name(T.schema_id) AS SchemaName, object_name(S.object_id) AS TableName, S.name AS StatisticsName, 
''USE ['' + DB_NAME() + '']; DROP STATISTICS ['' + schema_name(T.schema_id) + ''].['' + object_name(S.object_id) + ''].['' + S.name + '']'' AS DropStatement 
FROM sys.stats AS S 
INNER JOIN sys.tables AS T ON T.object_id = S.object_id 
WHERE S.user_created = 1',
                     @user_only = 1;

SELECT [Database],
       SchemaName,
       TableName,
       StatisticsName,
       DropStatement
FROM tempdb.dbo.UserCreatedStats
ORDER BY [Database],
         SchemaName,
         TableName,
         StatisticsName,
         DropStatement;

DROP TABLE tempdb.dbo.UserCreatedStats;
