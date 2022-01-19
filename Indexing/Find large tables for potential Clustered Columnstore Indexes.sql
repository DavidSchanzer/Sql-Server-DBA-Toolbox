WITH BigTables AS (SELECT SCHEMA_NAME(schema_id) AS [SchemaName], [Tables].name AS [TableName], SUM([Partitions].[rows]) AS [TotalRowCount]
                   FROM sys.tables AS [Tables]
                        JOIN sys.partitions AS [Partitions] ON [Tables].[object_id]=[Partitions].[object_id] AND [Partitions].index_id IN (0, 1)
                   GROUP BY SCHEMA_NAME(schema_id), [Tables].name
                   HAVING SUM([Partitions].[rows])>1000000)
SELECT b.SchemaName, b.TableName, b.TotalRowCount
FROM BigTables AS b
WHERE NOT EXISTS (SELECT *
                  FROM sys.indexes AS i
                  WHERE i.object_id=OBJECT_ID(b.SchemaName + '.' + b.TableName) AND i.type_desc='CLUSTERED COLUMNSTORE')
ORDER BY b.TableName;
