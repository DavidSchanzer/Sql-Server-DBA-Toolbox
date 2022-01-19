WITH ForeignKeys
AS (SELECT objconstraint.name AS ForeignKeyName,
           fkcols.name AS SchemaName,
           objfk.name AS TableName,
           STUFF(
           (
               SELECT ',' + col.name
               FROM sys.foreign_key_columns AS fkcol2
                   JOIN sys.columns AS col
                       ON fkcol2.parent_object_id = col.object_id
                          AND fkcol2.parent_column_id = col.column_id
                          AND fkcol2.constraint_object_id = fkcol.constraint_object_id
           ),
           1,
           1,
           ''
                ) AS ColumnNames -- + ');'
    FROM sys.foreign_key_columns AS fkcol
        JOIN sys.objects AS objfk
            ON fkcol.parent_object_id = objfk.object_id
        JOIN sys.schemas AS fkcols
            ON fkcols.schema_id = objfk.schema_id
        JOIN sys.objects AS objconstraint
            ON fkcol.constraint_object_id = objconstraint.object_id
        LEFT JOIN sys.index_columns AS ic
            ON ic.object_id = fkcol.parent_object_id
               AND ic.column_id = fkcol.parent_column_id
               AND ic.index_column_id = fkcol.constraint_column_id
    WHERE ic.object_id IS NULL)
SELECT DISTINCT '[' + ForeignKeys.SchemaName + '].[' + ForeignKeys.TableName + '].['+ ForeignKeyName + ']' AS ForeignKey,
       'CREATE NONCLUSTERED INDEX IX_' + ForeignKeys.TableName + '_' + ForeignKeys.ColumnNames + ' ON '
       + ForeignKeys.SchemaName + '.' + ForeignKeys.TableName + '(' + ForeignKeys.ColumnNames + ');' AS CreateIndexStatement
FROM ForeignKeys
ORDER BY ForeignKey;
