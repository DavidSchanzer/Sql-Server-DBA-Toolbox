-- SQL Server permissions list for read and write access for all databases
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists the instance-level and database-level permissions
-- From: https://www.mssqltips.com/sqlservertip/6145/sql-server-permissions-list-for-read-and-write-access-for-all-databases/

;WITH explicit
AS (SELECT p.principal_id,
           p.name,
           p.type_desc,
           p.create_date,
           p.is_disabled,
           dbp.permission_name COLLATE DATABASE_DEFAULT AS permission,
           CAST('' AS sysname) AS grant_through
    FROM sys.server_permissions dbp
        INNER JOIN sys.server_principals p
            ON dbp.grantee_principal_id = p.principal_id
    WHERE (
              dbp.type IN ( 'CL', 'TO', 'IM', 'ADBO' )
              OR dbp.type LIKE 'AL%'
          )
          AND dbp.state IN ( 'G', 'W' )
    UNION ALL
    SELECT dp.principal_id,
           dp.name,
           dp.type_desc,
           dp.create_date,
           dp.is_disabled,
           p.permission COLLATE DATABASE_DEFAULT,
           p.name COLLATE DATABASE_DEFAULT
    FROM sys.server_principals dp
        INNER JOIN sys.server_role_members rm
            ON rm.member_principal_id = dp.principal_id
        INNER JOIN explicit p
            ON p.principal_id = rm.role_principal_id),
      fixed
AS (SELECT dp.principal_id,
           dp.name,
           dp.type_desc,
           dp.create_date,
           dp.is_disabled,
           p.name COLLATE DATABASE_DEFAULT AS permission,
           CAST('' COLLATE DATABASE_DEFAULT AS sysname) AS grant_through
    FROM sys.server_principals dp
        INNER JOIN sys.server_role_members rm
            ON rm.member_principal_id = dp.principal_id
        INNER JOIN sys.server_principals p
            ON p.principal_id = rm.role_principal_id
    WHERE p.name IN ( 'sysadmin', 'securityadmin', 'bulkadmin' )
    UNION ALL
    SELECT dp.principal_id,
           dp.name,
           dp.type_desc,
           dp.create_date,
           dp.is_disabled,
           p.permission COLLATE DATABASE_DEFAULT,
           p.name COLLATE DATABASE_DEFAULT
    FROM sys.server_principals dp
        INNER JOIN sys.server_role_members rm
            ON rm.member_principal_id = dp.principal_id
        INNER JOIN fixed p
            ON p.principal_id = rm.role_principal_id)
SELECT DISTINCT
       explicit.name,
       explicit.type_desc,
       explicit.create_date,
       explicit.is_disabled,
       explicit.permission,
       explicit.grant_through
FROM explicit
WHERE explicit.type_desc NOT IN ( 'SERVER_ROLE' )
      AND explicit.name NOT IN ( 'sa', 'SQLDBO', 'SQLNETIQ' )
      AND explicit.name NOT LIKE '##%'
      AND explicit.name NOT LIKE 'NT SERVICE%'
      AND explicit.name NOT LIKE 'NT AUTHORITY%'
      AND explicit.name NOT LIKE 'BUILTIN%'
UNION ALL
SELECT DISTINCT
       fixed.name,
       fixed.type_desc,
       fixed.create_date,
       fixed.is_disabled,
       fixed.permission,
       fixed.grant_through
FROM fixed
WHERE fixed.type_desc NOT IN ( 'SERVER_ROLE' )
      AND fixed.name NOT IN ( 'sa', 'SQLDBO', 'SQLNETIQ' )
      AND fixed.name NOT LIKE '##%'
      AND fixed.name NOT LIKE 'NT SERVICE%'
      AND fixed.name NOT LIKE 'NT AUTHORITY%'
      AND fixed.name NOT LIKE 'BUILTIN%'
ORDER BY name
OPTION (MAXRECURSION 10);

CREATE TABLE #Info
(
    [database] sysname NOT NULL,
    username sysname NOT NULL,
    type_desc NVARCHAR(60) NOT NULL,
    create_date DATETIME NOT NULL,
    permission sysname NOT NULL,
    grant_through sysname NOT NULL
);

DECLARE @cmd VARCHAR(MAX);

SET @cmd = '';

SELECT @cmd
    = @cmd + 'INSERT #Info EXEC(''
USE ['        + name
      + ']
;WITH 
[explicit] AS (
   SELECT [p].[principal_id], [p].[name], [p].[type_desc], [p].[create_date],
         [dbp].[permission_name] COLLATE SQL_Latin1_General_CP1_CI_AS [permission],
         CAST('''''''' AS SYSNAME) [grant_through]
   FROM [sys].[database_permissions] [dbp]
   INNER JOIN [sys].[database_principals] [p] ON [dbp].[grantee_principal_id] = [p].[principal_id]
   WHERE ([dbp].[type] IN (''''IN'''',''''UP'''',''''DL'''',''''CL'''',''''DABO'''',''''IM'''',''''SL'''',''''TO'''') OR [dbp].[type] LIKE ''''AL%'''' OR [dbp].[type] LIKE ''''CR%'''')
     AND [dbp].[state] IN (''''G'''',''''W'''')
   UNION ALL
   SELECT [dp].[principal_id], [dp].[name], [dp].[type_desc], [dp].[create_date], [p].[permission], [p].[name] [grant_through]
   FROM [sys].[database_principals] [dp]
   INNER JOIN [sys].[database_role_members] [rm] ON [rm].[member_principal_id] = [dp].[principal_id]
   INNER JOIN [explicit] [p] ON [p].[principal_id] = [rm].[role_principal_id]
   ),
[fixed] AS (
   SELECT [dp].[principal_id], [dp].[name], [dp].[type_desc], [dp].[create_date], [p].[name] [permission], CAST('''''''' AS SYSNAME) [grant_through]
   FROM [sys].[database_principals] [dp]
   INNER JOIN [sys].[database_role_members] [rm] ON [rm].[member_principal_id] = [dp].[principal_id]
   INNER JOIN [sys].[database_principals] [p] ON [p].[principal_id] = [rm].[role_principal_id]
   WHERE [p].[name] IN (''''db_owner'''',''''db_datareader'''',''''db_datawriter'''',''''db_ddladmin'''',''''db_securityadmin'''',''''db_accessadmin'''')
   UNION ALL
   SELECT [dp].[principal_id], [dp].[name], [dp].[type_desc], [dp].[create_date], [p].[permission], [p].[name] [grant_through]
   FROM [sys].[database_principals] [dp]
   INNER JOIN [sys].[database_role_members] [rm] ON [rm].[member_principal_id] = [dp].[principal_id]
   INNER JOIN [fixed] [p] ON [p].[principal_id] = [rm].[role_principal_id]
   )
SELECT DB_NAME(), [name], [type_desc], [create_date], [permission], [grant_through]
FROM [explicit]
WHERE [type_desc] NOT IN (''''DATABASE_ROLE'''')
UNION ALL
SELECT DB_NAME(), [name], [type_desc], [create_date], [permission], [grant_through]
FROM [fixed]
WHERE [type_desc] NOT IN (''''DATABASE_ROLE'''')
OPTION(MAXRECURSION 10)
'');'
FROM sys.databases
WHERE state_desc = 'ONLINE';

EXEC (@cmd);

SELECT DISTINCT
       [database],
       username,
       type_desc,
       create_date,
       permission,
       grant_through
FROM #Info
WHERE username NOT IN ( 'dbo', 'guest', 'SQLDBO' )
      AND username NOT LIKE '##%'
      AND [database] NOT IN ( 'master', 'model', 'msdb', 'tempdb' )
ORDER BY [database],
         username;

DROP TABLE #Info;
