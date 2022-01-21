-- Find all non-indexed foreign keys
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script generates CREATE NONCLUSTERED INDEX statements for all defined foreign keys that don't also have a corresponding index.
-- This can be useful for databases with poor index design, as a first cut to improve it.
-- It includes options WITH (ONLINE=ON, DATA_COMPRESSION=PAGE), so alter or remove these if not suitable for your environment.
-- From https://www.mssqltips.com/sqlservertip/5004/script-to-identify-all-nonindexed-foreign-keys-in-a-sql-server-database/

SELECT OBJECT_NAME(a.parent_object_id) AS Table_Name,
       b.name AS Column_Name,
       'CREATE NONCLUSTERED INDEX IX_' + OBJECT_NAME(a.parent_object_id) + '_' + b.name + ' ON '
       + SCHEMA_NAME(c.schema_id) + '.' + OBJECT_NAME(a.parent_object_id) + '(' + b.name
       + ') WITH (ONLINE=ON, DATA_COMPRESSION=PAGE);' AS Create_Index_Statement
FROM sys.foreign_key_columns a
    INNER JOIN sys.all_columns b
        ON a.parent_column_id = b.column_id
           AND a.parent_object_id = b.object_id
    INNER JOIN sys.objects c
        ON b.object_id = c.object_id
WHERE c.is_ms_shipped = 0
EXCEPT
SELECT OBJECT_NAME(a.object_id),
       b.name,
       'CREATE NONCLUSTERED INDEX IX_' + OBJECT_NAME(a.object_id) + '_' + b.name + ' ON ' + SCHEMA_NAME(c.schema_id)
       + '.' + OBJECT_NAME(a.object_id) + '(' + b.name + ') WITH (ONLINE=ON, DATA_COMPRESSION=PAGE);'
FROM sys.index_columns a
    INNER JOIN sys.all_columns b
        ON a.object_id = b.object_id
           AND a.column_id = b.column_id
    INNER JOIN sys.objects c
        ON a.object_id = c.object_id
WHERE a.key_ordinal = 1
      AND c.is_ms_shipped = 0;
GO
