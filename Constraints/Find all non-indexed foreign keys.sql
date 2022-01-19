-- From https://www.mssqltips.com/sqlservertip/5004/script-to-identify-all-nonindexed-foreign-keys-in-a-sql-server-database/
SELECT OBJECT_NAME(a.parent_object_id) AS Table_Name,
       b.name AS Column_Name,
	   'CREATE NONCLUSTERED INDEX IX_' + OBJECT_NAME(a.parent_object_id) + '_' + b.name + ' ON '
       + SCHEMA_NAME(c.schema_id) + '.' + OBJECT_NAME(a.parent_object_id) + '(' + b.name + ') WITH (ONLINE=ON, DATA_COMPRESSION=PAGE);' AS Create_Index_Statement
FROM sys.foreign_key_columns a,
     sys.all_columns b,
     sys.objects c
WHERE a.parent_column_id = b.column_id
      AND a.parent_object_id = b.object_id
      AND b.object_id = c.object_id
      AND c.is_ms_shipped = 0
EXCEPT
SELECT OBJECT_NAME(a.object_id),
       b.name,
	   'CREATE NONCLUSTERED INDEX IX_' + OBJECT_NAME(a.object_id) + '_' + b.name + ' ON '
       + SCHEMA_NAME(c.schema_id) + '.' + OBJECT_NAME(a.object_id) + '(' + b.name + ') WITH (ONLINE=ON, DATA_COMPRESSION=PAGE);'
FROM sys.index_columns a,
     sys.all_columns b,
     sys.objects c
WHERE a.object_id = b.object_id
      AND a.key_ordinal = 1
      AND a.column_id = b.column_id
      AND a.object_id = c.object_id
      AND c.is_ms_shipped = 0
GO
