-- Set fillfactor to 100
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script generates ALTER INDEX statements to set Fillfactor to 100 for all indexes where it is set to neither 0 nor 100

EXEC dbo.sp_ineachdb @command = '
SELECT i.name AS IndexName, i.[fill_factor], SCHEMA_NAME(t.[schema_id]) AS SchemaName, t.[name] AS TableName, ''USE ?; ALTER INDEX ['' + i.name + ''] ON ['' + SCHEMA_NAME(t.[schema_id]) + ''].['' + t.name + ''] REBUILD WITH (FILLFACTOR = 100, ONLINE = ON);''
FROM sys.indexes AS i
INNER JOIN sys.tables AS t ON [t].[object_id] = [i].[object_id]
WHERE i.fill_factor NOT IN (0, 100)
AND i.is_disabled = 0 AND i.is_hypothetical = 0;
';
