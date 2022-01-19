-- From http://www.mssqltips.com/sqlservertip/3347/drop-and-recreate-all-foreign-key-constraints-in-sql-server/

CREATE TABLE #x -- feel free to use a permanent table
    (
      drop_script NVARCHAR(MAX) ,
      create_script NVARCHAR(MAX)
    );
  
DECLARE @drop NVARCHAR(MAX) = N'' ,
    @create NVARCHAR(MAX) = N'';

-- drop is easy, just build a simple concatenated list from sys.foreign_keys:
SELECT  @drop += N'
ALTER TABLE ' + QUOTENAME(cs.name) + '.' + QUOTENAME(ct.name)
        + ' DROP CONSTRAINT ' + QUOTENAME(fk.name) + ';'
FROM    sys.foreign_keys AS fk
        INNER JOIN sys.tables AS ct ON fk.parent_object_id = ct.[object_id]
        INNER JOIN sys.schemas AS cs ON ct.[schema_id] = cs.[schema_id];

INSERT  #x
        ( drop_script )
        SELECT  @drop;

-- create is a little more complex. We need to generate the list of 
-- columns on both sides of the constraint, even though in most cases
-- there is only one column.
SELECT  @create += N'
ALTER TABLE ' + QUOTENAME(cs.name) + '.' + QUOTENAME(ct.name)
        + ' ADD CONSTRAINT ' + QUOTENAME(fk.name) + ' FOREIGN KEY ('
        + STUFF((SELECT ',' + QUOTENAME(c.name)
   -- get all the columns in the constraint table
                 FROM   sys.columns AS c
                        INNER JOIN sys.foreign_key_columns AS fkc ON fkc.parent_column_id = c.column_id
                                                              AND fkc.parent_object_id = c.[object_id]
                 WHERE  fkc.constraint_object_id = fk.[object_id]
                 ORDER BY fkc.constraint_column_id
        FOR     XML PATH(N'') ,
                    TYPE).value(N'.[1]', N'nvarchar(max)'), 1, 1, N'')
        + ') REFERENCES ' + QUOTENAME(rs.name) + '.' + QUOTENAME(rt.name)
        + '('
        + STUFF((SELECT ',' + QUOTENAME(c.name)
   -- get all the referenced columns
                 FROM   sys.columns AS c
                        INNER JOIN sys.foreign_key_columns AS fkc ON fkc.referenced_column_id = c.column_id
                                                              AND fkc.referenced_object_id = c.[object_id]
                 WHERE  fkc.constraint_object_id = fk.[object_id]
                 ORDER BY fkc.constraint_column_id
        FOR     XML PATH(N'') ,
                    TYPE).value(N'.[1]', N'nvarchar(max)'), 1, 1, N'') + ');'
FROM    sys.foreign_keys AS fk
        INNER JOIN sys.tables AS rt -- referenced table
        ON fk.referenced_object_id = rt.[object_id]
        INNER JOIN sys.schemas AS rs ON rt.[schema_id] = rs.[schema_id]
        INNER JOIN sys.tables AS ct -- constraint table
        ON fk.parent_object_id = ct.[object_id]
        INNER JOIN sys.schemas AS cs ON ct.[schema_id] = cs.[schema_id]
WHERE   rt.is_ms_shipped = 0
        AND ct.is_ms_shipped = 0;

UPDATE  #x
SET     create_script = @create;

PRINT @drop;
PRINT @create;

/*
EXEC sp_executesql @drop
-- clear out data etc. here
EXEC sp_executesql @create;
*/
