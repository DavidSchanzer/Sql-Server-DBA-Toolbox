EXEC sp_ineachdb @command = '
SELECT i.name AS IndexName, i.[fill_factor], SCHEMA_NAME(t.[schema_id]) AS SchemaName, t.[name] AS TableName, ''USE ?; ALTER INDEX ['' + i.name + ''] ON ['' + SCHEMA_NAME(t.[schema_id]) + ''].['' + t.name + ''] REBUILD WITH (FILLFACTOR = 100, ONLINE = ON);''
FROM sys.indexes AS i
INNER JOIN sys.tables AS t ON [t].[object_id] = [i].[object_id]
WHERE i.fill_factor NOT IN (0, 100)
AND i.is_disabled = 0 AND i.is_hypothetical = 0;
';
