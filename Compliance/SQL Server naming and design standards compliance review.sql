-- SQL Server Naming and Design Standards
-- Tables with a name that begins with 'tbl'
SELECT name
FROM sys.tables
WHERE name LIKE 'tbl%'
ORDER BY name;

-- Tables with a name that contains something other than letters and numbers
SELECT name
FROM sys.tables
WHERE name LIKE '%[^A-Z^a-z^0-9]%'
ORDER BY name;

-- Tables with a pluralised name
SELECT name
FROM sys.tables
WHERE name LIKE '%s'
      AND name <> 'sysdiagrams'
ORDER BY name;

-- Tables without a Primary Key
SELECT name AS TableName
FROM sys.tables
WHERE OBJECTPROPERTY(object_id, 'TableHasPrimaryKey') = 0
ORDER BY name;

-- Tables without a Clustered Index
SELECT name AS TableName
FROM sys.tables
WHERE OBJECTPROPERTY(object_id, 'TableHasClustIndex') = 0
ORDER BY name;

-- Tables with an improperly-named Primary Key
SELECT OBJECT_NAME(parent_object_id) AS TableName,
       OBJECT_NAME(object_id) AS NameofConstraint
FROM sys.objects
WHERE type_desc = 'PRIMARY_KEY_CONSTRAINT'
      AND OBJECT_NAME(object_id) != 'PK_' + OBJECT_NAME(parent_object_id)
      AND OBJECT_NAME(object_id) != 'PK_' + SCHEMA_NAME(schema_id) + '.' + OBJECT_NAME(parent_object_id);

-- Tables without a Foreign Key or a Foreign Key Reference
SELECT name AS TableName
FROM sys.tables
WHERE OBJECTPROPERTY(object_id, 'TableHasForeignKey') = 0
      AND OBJECTPROPERTY(object_id, 'TableHasForeignRef') = 0
      AND name <> 'sysdiagrams'
ORDER BY name;

-- Tables with an improperly-named Foreign Key
SELECT name AS foreign_key_name,
       'FK_' + OBJECT_NAME(parent_object_id) + '_' + OBJECT_NAME(referenced_object_id) + '_%' AS correct_foreign_key_name,
       OBJECT_NAME(parent_object_id) AS table_name,
       OBJECT_NAME(referenced_object_id) AS referenced_table_name
FROM sys.foreign_keys
WHERE name NOT LIKE 'FK_' + OBJECT_NAME(parent_object_id) + '_' + OBJECT_NAME(referenced_object_id) + '_%'
      AND name NOT LIKE 'FK_' + SCHEMA_NAME(schema_id) + '.' + OBJECT_NAME(parent_object_id) + '_'
                        + SCHEMA_NAME(schema_id) + '.' + OBJECT_NAME(referenced_object_id) + '_%'
--        AND OBJECT_NAME(parent_object_id) = OBJECT_NAME(referenced_object_id)
ORDER BY name;

-- Foreign keys that are not trusted
SELECT OBJECT_NAME(i.parent_object_id) AS TableName,
       i.name AS ForeignKeyName
FROM sys.foreign_keys i
    INNER JOIN sys.objects o
        ON i.parent_object_id = o.object_id
    INNER JOIN sys.schemas s
        ON o.schema_id = s.schema_id
WHERE i.is_not_trusted = 1
      AND i.is_not_for_replication = 0
      AND i.is_disabled = 0
ORDER BY OBJECT_NAME(i.parent_object_id),
         i.name;

-- Columns that don't use Pascal case (list all and check for inconsistencies manually)
SELECT c.name AS ColumnName,
       OBJECT_NAME(c.object_id) AS TableName,
       SCHEMA_NAME(t.schema_id) AS SchemaName
FROM sys.columns AS c
    LEFT OUTER JOIN sys.tables AS t
        ON t.object_id = c.object_id
WHERE OBJECT_NAME(c.object_id)NOT LIKE 'sys%'
      AND OBJECT_NAME(c.object_id)NOT LIKE 'queue_messages_%'
      AND OBJECT_NAME(c.object_id)NOT LIKE 'filestream_%'
ORDER BY c.name,
         OBJECT_NAME(c.object_id);

-- Columns with inconsistent data types
SELECT c.name AS ColumnName,
       CASE
           WHEN t.name IN ( 'char', 'nchar', 'varchar', 'nvarchar' ) THEN
               t.name + '(' + CASE
                                  WHEN c.max_length = -1 THEN
                                      'max'
                                  ELSE
                                      CAST(c.max_length AS VARCHAR)
                              END + ')'
           ELSE
               t.name
       END AS ColumnType,
       OBJECT_NAME(c.object_id) AS TableName
FROM sys.columns AS c
    INNER JOIN sys.types AS t
        ON c.system_type_id = t.system_type_id
           AND c.user_type_id = t.user_type_id
WHERE c.name IN
      (
          SELECT name
          FROM
          (
              SELECT DISTINCT
                     name,
                     system_type_id,
                     max_length
              FROM sys.columns
              WHERE OBJECT_NAME(object_id)NOT LIKE 'sys%'
                    AND OBJECT_NAME(object_id)NOT LIKE 'filestream_%'
                    AND OBJECT_NAME(object_id)NOT LIKE 'queue_messages_%'
          ) AS DT
          GROUP BY name
          HAVING COUNT(*) > 1
      )
      AND OBJECT_NAME(c.object_id)NOT LIKE 'sys%'
      AND OBJECT_NAME(object_id)NOT LIKE 'filestream_%'
      AND OBJECT_NAME(object_id)NOT LIKE 'queue_messages_%'
ORDER BY c.name,
         CASE
             WHEN t.name IN ( 'char', 'nchar', 'varchar', 'nvarchar' ) THEN
                 t.name + '(' + CASE
                                    WHEN c.max_length = -1 THEN
                                        'max'
                                    ELSE
                                        CAST(c.max_length AS VARCHAR)
                                END + ')'
             ELSE
                 t.name
         END,
         OBJECT_NAME(c.object_id);

-- Triggers with an incorrect name (need to manually ensure that trigger name is suffixed with trigger type eg. tr_ChimeraRole_InsertUpdate)
SELECT name AS trigger_name,
       OBJECT_NAME(parent_id) AS table_name
FROM sys.triggers
WHERE name NOT LIKE 'tr_' + OBJECT_NAME(object_id) + '_%'
ORDER BY name;

-- Indices with an incorrect name
SELECT name AS index_name,
       'IX_' + OBJECT_NAME(object_id) + '_%' AS correct_index_name,
       OBJECT_NAME(object_id) AS table_name
FROM sys.indexes
WHERE object_id > 100
      AND type_desc = 'NONCLUSTERED'
      AND name NOT LIKE 'IX[_]' + OBJECT_NAME(object_id) + '[_]%'
      AND OBJECT_NAME(object_id)NOT LIKE 'sys%'
      AND name NOT IN ( 'queue_secondary_index', 'FSTSNCIdx' )
      AND name NOT LIKE 'PK[_]%'
ORDER BY OBJECT_NAME(object_id);

-- Stored Procedures with an incorrect name
SELECT name
FROM sys.procedures
WHERE name NOT IN ( 'sp_upgraddiagrams', 'sp_helpdiagrams', 'sp_helpdiagramdefinition', 'sp_creatediagram',
                    'sp_renamediagram', 'sp_alterdiagram', 'sp_dropdiagram'
                  )
      AND name NOT LIKE 'usp_%'
ORDER BY name;

-- User-Defined Functions with an incorrect name
SELECT name
FROM sys.objects
WHERE type_desc LIKE '%FUNCTION%'
      AND name <> 'fn_diagramobjects'
      AND name NOT LIKE 'udf_%'
ORDER BY name;

-- Views with an incorrect name
SELECT name
FROM sys.views
WHERE name NOT LIKE 'v%'
ORDER BY name;

-- All indices
SELECT OBJECT_NAME(object_id) AS TableName,
       name AS IndexName
FROM sys.indexes
WHERE type_desc = 'NONCLUSTERED'
      AND OBJECT_NAME(object_id)NOT LIKE 'sys%'
      AND OBJECT_NAME(object_id)NOT LIKE 'queue_messages_%'
      AND OBJECT_NAME(object_id)NOT LIKE 'filestream_%'
ORDER BY OBJECT_NAME(object_id);

-- Tables with deprecated data types
SELECT s.[name] AS SchemaName,
       t.[name] AS TableName,
       c.[name] AS ColumnName,
       typ.[name] + CASE
                        WHEN typ.[name] IN ( N'decimal', N'numeric' ) THEN
                            N'(' + CAST(c.precision AS NVARCHAR(20)) + N', ' + CAST(c.scale AS NVARCHAR(20)) + N')'
                        WHEN typ.[name] IN ( N'varchar', N'nvarchar', N'char', N'nchar' ) THEN
                            N'(' + CASE
                                       WHEN c.max_length < 0 THEN
                                           N'max'
                                       ELSE
                                           CAST(c.max_length AS NVARCHAR(20))
                                   END + N')'
                        WHEN typ.[name] IN ( N'time', N'datetime2', N'datetimeoffset' ) THEN
                            N'(' + CAST(c.scale AS NVARCHAR(20)) + N')'
                        ELSE
                            N''
                    END AS DataType,
       CASE typ.[name]
           WHEN N'image' THEN
               'varbinary(max)'
           WHEN N'text' THEN
               'varchar(max)'
           WHEN N'ntext' THEN
               'nvarchar(max)'
       END AS SuggestedReplacementType
FROM sys.schemas AS s
    INNER JOIN sys.tables AS t
        ON s.[schema_id] = t.[schema_id]
    INNER JOIN sys.columns AS c
        ON t.[object_id] = c.[object_id]
    INNER JOIN sys.[types] AS typ
        ON c.system_type_id = typ.system_type_id
           AND c.user_type_id = typ.user_type_id
WHERE t.[type] = N'U'
      AND typ.[name] IN ( 'image', 'text', 'ntext' )
ORDER BY SchemaName,
         TableName,
         c.column_id;

-- Remember to also run sp_blitz! (http://www.BrentOzar.com/go/blitz)
EXEC master.dbo.sp_Blitz @CheckUserDatabaseObjects = 1;
