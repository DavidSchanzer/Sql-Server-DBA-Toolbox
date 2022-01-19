SELECT DISTINCT
       DB_NAME() AS db,
       SCHEMA_NAME(o.schema_id) AS schema_name,
       o.name AS table_name,
       o.create_date AS table_create_date,
       i.name AS index_name,
       i.fill_factor AS fill_factor,
       p.rows AS table_row_count,
       'ALTER INDEX [' + i.name + '] ON [' + DB_NAME() + '].' + SCHEMA_NAME(o.schema_id) + '.' + o.name + ' REBUILD'
       + CASE
             WHEN i.fill_factor = 70 THEN
                 ' WITH (FILLFACTOR = 100, ONLINE=ON)'
             ELSE
                 ''
         END + ';' AS reindex_command
FROM sys.objects AS o
    INNER JOIN sys.indexes AS i
        ON o.object_id = i.object_id
    INNER JOIN sys.partitions AS p
        ON o.object_id = p.object_id
WHERE i.index_id > 0
      AND o.is_ms_shipped = 0

      --AND p.rows > 1000000

      AND i.fill_factor = 70
ORDER BY p.rows DESC;