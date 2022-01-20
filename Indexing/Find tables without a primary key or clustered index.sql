EXEC dbo.sp_ineachdb @command = '
SELECT ''?'', SCHEMA_NAME(schema_id) AS schema_name, name AS TableName, OBJECTPROPERTY(object_id, ''TableHasPrimaryKey'') AS HasPrimaryKey, OBJECTPROPERTY(object_id, ''TableHasClustIndex'') AS HasClusteredIndex
FROM    sys.tables
WHERE   (OBJECTPROPERTY(object_id, ''TableHasPrimaryKey'') = 0 OR OBJECTPROPERTY(object_id, ''TableHasClustIndex'') = 0)
ORDER BY schema_name, name
',
                     @user_only = 1;
