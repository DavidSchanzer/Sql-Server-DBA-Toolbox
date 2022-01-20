-- Generate script to change all users to have default schema of dbo
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists all users in each database that don't have a Default Schema value assigned (normally set to 'dbo').
-- The implication of not having a Default Schema value assigned for each AD group user is that any object created then automatically creates a schema
-- and places the object within that schema, rather than in the dbo schema.

CREATE TABLE #UsersWithNoDefaultSchema
(
    DatabaseName sysname NULL,
    UserName sysname NULL,
    DefaultSchemaName sysname NULL,
    Command VARCHAR(1000) NULL
);

INSERT INTO #UsersWithNoDefaultSchema
(
    DatabaseName,
    UserName,
    DefaultSchemaName,
    Command
)
EXEC dbo.sp_ineachdb @command = '
SELECT DB_NAME() AS DatabaseName, name AS UserName, default_schema_name AS DefaultSchemaName, ''USE ?; ALTER USER ['' + name + ''] WITH DEFAULT_SCHEMA = [dbo];'' AS Command
FROM sys.database_principals
WHERE type = ''G''
AND default_schema_name IS NULL;
',
                     @exclude_list = 'tempdb';

SELECT DatabaseName,
       UserName,
       DefaultSchemaName,
       Command
FROM #UsersWithNoDefaultSchema;
DROP TABLE #UsersWithNoDefaultSchema;

-- Script to move tables that have been created under the user's own schema to the dbo schema
--SELECT name, 'ALTER SCHEMA dbo TRANSFER [xxxxxxxx].[' + name + '];' FROM sys.tables
-- Don't forget to drop the now-unnecessary schema and user
--DROP SCHEMA [xxxxxxxx];
--DROP USER [xxxxxxxx];
