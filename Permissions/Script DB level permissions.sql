/*
This script will script the role members for all roles on the database.

This is useful for scripting permissions in a development environment before refreshing
	development with a copy of production.  This will allow us to easily ensure
	development permissions are not lost during a prod to dev restoration. 
	
Author: S. Kusen

Updates:

05/14/2012: Incorporated a fix pointed out by aruopna for Schema-level permissions.

01/20/2010:	Turned statements into a cursor and then using print statements to make it easier to 
		copy/paste into a query window.
		Added support for schema level permissions


Thanks to wsoranno@winona.edu and choffman for the recommendations.

*/

/* ***************************************************** */
/* Script the role members for all roles on the database */
/* ***************************************************** */

DECLARE @sql VARCHAR(2048),
        @sort INT;
DECLARE tmp CURSOR FOR

/*********************************************/
/*********   DB CONTEXT STATEMENT    *********/
/*********************************************/
SELECT '-- [-- DB CONTEXT --] --' AS [-- SQL STATEMENTS --],
       1 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT 'USE' + SPACE(1) + QUOTENAME(DB_NAME()) AS [-- SQL STATEMENTS --],
       1 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT '' AS [-- SQL STATEMENTS --],
       2 AS [-- RESULT ORDER HOLDER --]
UNION

/*********************************************/
/*********     DB USER CREATION      *********/
/*********************************************/
SELECT '-- [-- DB USERS --] --' AS [-- SQL STATEMENTS --],
       3 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT 'IF NOT EXISTS (SELECT [name] FROM sys.database_principals WHERE [name] = ' + SPACE(1) + '''' + [name] + ''''
       + ') 
         BEGIN CREATE USER' + SPACE(1) + QUOTENAME([name]) + ' FOR LOGIN ' + QUOTENAME([name])
       + ' WITH DEFAULT_SCHEMA = ' + QUOTENAME([default_schema_name]) + SPACE(1)
       + 'END
         ELSE BEGIN IF EXISTS (SELECT * from master.dbo.syslogins WHERE loginname = ' + SPACE(1) + '''' + [name] + ''''
       + ') ALTER USER ' + QUOTENAME([name]) + ' WITH LOGIN = ' + QUOTENAME([name]) + ' ELSE IF ' + ''''
       + QUOTENAME([name]) + '''' + ' NOT IN (''[dbo]'',''[guest]'')  DROP USER ' + QUOTENAME([name]) + ' END;' AS [-- SQL STATEMENTS --],
       4 AS [-- RESULT ORDER HOLDER --]
FROM sys.database_principals AS rm
WHERE [type] IN ( 'U', 'S', 'G' ) -- windows users, sql users, windows groups
UNION

/*********************************************/
/*********    DB ROLE PERMISSIONS    *********/
/*********************************************/
SELECT '-- [-- DB ROLES --] --' AS [-- SQL STATEMENTS --],
       5 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT 'EXEC sp_addrolemember @rolename =' + SPACE(1) + QUOTENAME(USER_NAME(rm.role_principal_id), '''')
       + ', @membername =' + SPACE(1) + QUOTENAME(USER_NAME(rm.member_principal_id), '''') AS [-- SQL STATEMENTS --],
       6 AS [-- RESULT ORDER HOLDER --]
FROM sys.database_role_members AS rm
WHERE USER_NAME(rm.member_principal_id)
    --get user names on the database
    IN
      (
          SELECT [name]
          FROM sys.database_principals
          WHERE [principal_id] > 4 -- 0 to 4 are system users/schemas
                AND [type] IN ( 'G', 'S', 'U' ) -- S = SQL user, U = Windows user, G = Windows group
      )
UNION
SELECT '' AS [-- SQL STATEMENTS --],
       7 AS [-- RESULT ORDER HOLDER --]
UNION

/*********************************************/
/*********  OBJECT LEVEL PERMISSIONS *********/
/*********************************************/
SELECT '-- [-- OBJECT LEVEL PERMISSIONS --] --' AS [-- SQL STATEMENTS --],
       8 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT CASE
           WHEN perm.state <> 'W' THEN
               perm.state_desc
           ELSE
               'GRANT'
       END + SPACE(1) + perm.permission_name + SPACE(1) + 'ON ' + QUOTENAME(SCHEMA_NAME(obj.schema_id)) + '.'
       + QUOTENAME(obj.name) --select, execute, etc on specific objects
       + CASE
             WHEN cl.column_id IS NULL THEN
                 SPACE(0)
             ELSE
                 '(' + QUOTENAME(cl.name) + ')'
         END + SPACE(1) + 'TO' + SPACE(1) + QUOTENAME(USER_NAME(usr.principal_id)) COLLATE DATABASE_DEFAULT
       + CASE
             WHEN perm.state <> 'W' THEN
                 SPACE(0)
             ELSE
                 SPACE(1) + 'WITH GRANT OPTION'
         END AS [-- SQL STATEMENTS --],
       9 AS [-- RESULT ORDER HOLDER --]
FROM sys.database_permissions AS perm
    INNER JOIN sys.objects AS obj
        ON perm.major_id = obj.[object_id]
    INNER JOIN sys.database_principals AS usr
        ON perm.grantee_principal_id = usr.principal_id
    LEFT JOIN sys.columns AS cl
        ON cl.column_id = perm.minor_id
           AND cl.[object_id] = perm.major_id
UNION
SELECT '' AS [-- SQL STATEMENTS --],
       10 AS [-- RESULT ORDER HOLDER --]
UNION

/*********************************************/
/*********    DB LEVEL PERMISSIONS   *********/
/*********************************************/
SELECT '-- [--DB LEVEL PERMISSIONS --] --' AS [-- SQL STATEMENTS --],
       11 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT CASE
           WHEN perm.state <> 'W' THEN
               perm.state_desc --W=Grant With Grant Option
           ELSE
               'GRANT'
       END + SPACE(1) + perm.permission_name --CONNECT, etc
       + SPACE(1) + 'TO' + SPACE(1) + '[' + USER_NAME(usr.principal_id) + ']' COLLATE DATABASE_DEFAULT --TO <user name>
       + CASE
             WHEN perm.state <> 'W' THEN
                 SPACE(0)
             ELSE
                 SPACE(1) + 'WITH GRANT OPTION'
         END AS [-- SQL STATEMENTS --],
       12 AS [-- RESULT ORDER HOLDER --]
FROM sys.database_permissions AS perm
    INNER JOIN sys.database_principals AS usr
        ON perm.grantee_principal_id = usr.principal_id
WHERE [perm].[major_id] = 0
      AND [usr].[principal_id] > 4 -- 0 to 4 are system users/schemas
      AND [usr].[type] IN ( 'G', 'S', 'U' ) -- S = SQL user, U = Windows user, G = Windows group
UNION
SELECT '' AS [-- SQL STATEMENTS --],
       13 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT '-- [--DB LEVEL SCHEMA PERMISSIONS --] --' AS [-- SQL STATEMENTS --],
       14 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT CASE
           WHEN perm.state <> 'W' THEN
               perm.state_desc --W=Grant With Grant Option
           ELSE
               'GRANT'
       END + SPACE(1) + perm.permission_name --CONNECT, etc
       + SPACE(1) + 'ON' + SPACE(1) + class_desc + '::' COLLATE DATABASE_DEFAULT --TO <user name>
       + QUOTENAME(SCHEMA_NAME(major_id)) + SPACE(1) + 'TO' + SPACE(1)
       + QUOTENAME(USER_NAME(grantee_principal_id)) COLLATE DATABASE_DEFAULT + CASE
                                                                                   WHEN perm.state <> 'W' THEN
                                                                                       SPACE(0)
                                                                                   ELSE
                                                                                       SPACE(1) + 'WITH GRANT OPTION'
                                                                               END AS [-- SQL STATEMENTS --],
       15 AS [-- RESULT ORDER HOLDER --]
FROM sys.database_permissions AS perm
    INNER JOIN sys.schemas s
        ON perm.major_id = s.schema_id
    INNER JOIN sys.database_principals dbprin
        ON perm.grantee_principal_id = dbprin.principal_id
WHERE class = 3 --class 3 = schema
ORDER BY [-- RESULT ORDER HOLDER --];
OPEN tmp;
FETCH NEXT FROM tmp
INTO @sql,
     @sort;
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT @sql;
    FETCH NEXT FROM tmp
    INTO @sql,
         @sort;
END;
CLOSE tmp;
DEALLOCATE tmp;
GO
