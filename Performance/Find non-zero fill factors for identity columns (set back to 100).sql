-- Find non-zero fill factors for identity columns (set back to 100)
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists identity columns that have a FILLFACTOR value that is neither 0 nor 100, and provides the ALTER INDEX statement to fix it.

EXEC dbo.sp_ineachdb @command = '
SELECT OBJECT_NAME(i.object_id) AS TableName,
       i.name AS index_name,
       COL_NAME(ic.object_id, ic.column_id) AS column_name,
       i.fill_factor AS fill_factor,
       ''ALTER INDEX ['' + i.name + ''] ON ['' + OBJECT_NAME(i.object_id)
       + ''] REBUILD WITH (SORT_IN_TEMPDB = OFF, ONLINE = ON, FILLFACTOR = 100)'' AS RebuildSQL
FROM sys.indexes AS i
    INNER JOIN sys.index_columns AS ic
        ON i.object_id = ic.object_id
           AND i.index_id = ic.index_id
    INNER JOIN sys.columns AS c
        ON c.object_id = ic.object_id
           AND c.column_id = ic.column_id
WHERE i.fill_factor <> 0
      AND i.fill_factor <> 100
      AND c.is_identity = 1;
';
