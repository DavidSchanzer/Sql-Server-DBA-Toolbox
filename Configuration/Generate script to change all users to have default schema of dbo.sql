CREATE TABLE #UsersWithNoDefaultSchema
(
    DatabaseName sysname,
    UserName sysname,
    DefaultSchemaName sysname NULL,
    Command VARCHAR(1000)
);

INSERT INTO #UsersWithNoDefaultSchema
EXEC sp_ineachdb @command = '
SELECT DB_NAME() AS DatabaseName, name AS UserName, default_schema_name AS DefaultSchemaName, ''USE ?; ALTER USER ['' + name + ''] WITH DEFAULT_SCHEMA = [dbo];'' AS Command
FROM sys.database_principals
WHERE type = ''G''
AND default_schema_name IS NULL;
',
                 @exclude_list = 'tempdb';

SELECT *
FROM #UsersWithNoDefaultSchema;
DROP TABLE #UsersWithNoDefaultSchema;

-- Script to move tables that have been created under the user's own schema to the dbo schema
--SELECT name, 'ALTER SCHEMA dbo TRANSFER [xxxxxxxx].[' + name + '];' FROM sys.tables
-- Don't forget to drop the now-unnecessary schema and user
--DROP SCHEMA [xxxxxxxx];
--DROP USER [xxxxxxxx];
