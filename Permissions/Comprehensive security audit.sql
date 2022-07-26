-- Comprehensive security audit
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script produces 3 result sets: Instance-level, Database-level and Object-level permissions.
--
-- Requirement:
-- This script requires the use of an existing table (through a Linked Server BLTZRESULTS): BLITZRESULTS.DBA_Rep.dbo.Staff
-- whose name you can obviously modify to suit your environment. It's defined as follows:
--		CREATE TABLE dbo.Staff (
--			Name CHAR(8) NOT NULL,
--			DisplayName VARCHAR(255) NOT NULL)
-- and populated with data that maps a person's AD Name (eg. 'jsmith') with their AD DisplayName ('John Smith').
-- This enables the result sets to include the DisplayName of individuals.
-- 
-- Based on: https://www.mssqltips.com/sqlservertip/6145/sql-server-permissions-list-for-read-and-write-access-for-all-databases/

-- Section 0: Populate the temp table #xpLogininfoOutput so that we can determine AD group membership using xp_logininfo
DECLARE @ErrorRecap TABLE
(
    ID INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
    AccountName NVARCHAR(256) NOT NULL,
    ErrorMessage NVARCHAR(256) NOT NULL
);

IF OBJECT_ID('tempdb.dbo.#xpLogininfoOutput') IS NOT NULL
    DROP TABLE #xpLogininfoOutput;

CREATE TABLE #xpLogininfoOutput
(
    AccountName NVARCHAR(256) NULL,
    Type VARCHAR(8) NULL,
    Privilege VARCHAR(8) NULL,
    MappedLoginName NVARCHAR(256) NULL,
    PermissionPath NVARCHAR(256) NULL
);

DECLARE @groupname NVARCHAR(256),
        @SQL NVARCHAR(256);

DECLARE c1 CURSOR LOCAL FORWARD_ONLY STATIC READ_ONLY FOR
SELECT name
FROM master.sys.server_principals
WHERE type_desc = 'WINDOWS_GROUP';

OPEN c1;

FETCH NEXT FROM c1
INTO @groupname;

WHILE @@FETCH_STATUS <> -1
BEGIN
    BEGIN TRY
        INSERT INTO #xpLogininfoOutput
        (
            AccountName,
            Type,
            Privilege,
            MappedLoginName,
            PermissionPath
        )
        EXEC master..xp_logininfo @acctname = @groupname, @option = 'members'; -- show group members
    END TRY
    BEGIN CATCH
        DECLARE @ErrorSeverity INT,
                @ErrorNumber INT,
                @ErrorMessage NVARCHAR(4000),
                @ErrorState INT;

        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorState = ERROR_STATE();

        --put all the errors in a table together
        INSERT INTO @ErrorRecap
        (
            AccountName,
            ErrorMessage
        )
        SELECT @groupname,
               @ErrorMessage;

        --echo out the supressed error, the try catch allows us to continue processing, instead of stopping on the first error
        PRINT 'Msg ' + CONVERT(VARCHAR(10), @ErrorNumber) + ' Level ' + CONVERT(VARCHAR(10), @ErrorSeverity) + ' State '
              + CONVERT(VARCHAR(10), @ErrorState);
        PRINT @ErrorMessage;
    END CATCH;
    FETCH NEXT FROM c1
    INTO @groupname;
END;
CLOSE c1;
DEALLOCATE c1;

-- Now temporarily create a login for any of these AD group members that is itself a group, so that we can enumerate its group members
DECLARE c2 CURSOR LOCAL FORWARD_ONLY STATIC READ_ONLY FOR
SELECT AccountName
FROM #xpLogininfoOutput
WHERE Type = 'group'
      AND PermissionPath NOT LIKE 'NT SERVICE\%';
OPEN c2;

FETCH NEXT FROM c2
INTO @groupname;

WHILE @@FETCH_STATUS <> -1
BEGIN
    BEGIN TRY
        SET @SQL = N'CREATE LOGIN [' + @groupname + N'] FROM WINDOWS';
        EXEC sys.sp_executesql @stmt = @SQL;

        INSERT INTO #xpLogininfoOutput
        (
            AccountName,
            Type,
            Privilege,
            MappedLoginName,
            PermissionPath
        )
        EXEC master..xp_logininfo @acctname = @groupname, @option = 'members'; -- show group members

        SET @SQL = N'DROP LOGIN [' + @groupname + N']';
        EXEC sys.sp_executesql @stmt = @SQL;
    END TRY
    BEGIN CATCH
        --capture the error details
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorState = ERROR_STATE();

        --put all the errors in a table together
        INSERT INTO @ErrorRecap
        (
            AccountName,
            ErrorMessage
        )
        SELECT @groupname,
               @ErrorMessage;

        --echo out the supressed error, the try catch allows us to continue processing, instead of stopping on the first error
        PRINT 'Msg ' + CONVERT(VARCHAR(10), @ErrorNumber) + ' Level ' + CONVERT(VARCHAR(10), @ErrorSeverity) + ' State '
              + CONVERT(VARCHAR(10), @ErrorState);
        PRINT @ErrorMessage;
    END CATCH;

    FETCH NEXT FROM c2
    INTO @groupname;
END;
CLOSE c2;
DEALLOCATE c2;

-- Section 1: Instance-level permissions
WITH explicit
AS (SELECT p.principal_id,
           p.name,
           p.type_desc,
           p.create_date,
           p.is_disabled,
           dbp.permission_name COLLATE DATABASE_DEFAULT AS permission,
           CAST('' AS sysname) AS grant_through
    FROM sys.server_permissions AS dbp
        INNER JOIN sys.server_principals AS p
            ON dbp.grantee_principal_id = p.principal_id
    UNION ALL
    SELECT dp.principal_id,
           dp.name,
           dp.type_desc,
           dp.create_date,
           dp.is_disabled,
           p.permission COLLATE DATABASE_DEFAULT,
           p.name COLLATE DATABASE_DEFAULT
    FROM sys.server_principals AS dp
        INNER JOIN sys.server_role_members AS rm
            ON rm.member_principal_id = dp.principal_id
        INNER JOIN explicit AS p
            ON p.principal_id = rm.role_principal_id),
     fixed
AS (SELECT dp.principal_id,
           dp.name,
           dp.type_desc,
           dp.create_date,
           dp.is_disabled,
           p.name COLLATE DATABASE_DEFAULT AS permission,
           CAST('' COLLATE DATABASE_DEFAULT AS sysname) AS grant_through
    FROM sys.server_principals AS dp
        INNER JOIN sys.server_role_members AS rm
            ON rm.member_principal_id = dp.principal_id
        INNER JOIN sys.server_principals AS p
            ON p.principal_id = rm.role_principal_id
    UNION ALL
    SELECT dp.principal_id,
           dp.name,
           dp.type_desc,
           dp.create_date,
           dp.is_disabled,
           p.permission COLLATE DATABASE_DEFAULT,
           p.name COLLATE DATABASE_DEFAULT
    FROM sys.server_principals AS dp
        INNER JOIN sys.server_role_members AS rm
            ON rm.member_principal_id = dp.principal_id
        INNER JOIN fixed AS p
            ON p.principal_id = rm.role_principal_id)
SELECT DISTINCT
       E.name AS [Section 1: Instance-level permissions - LoginName],
       E.type_desc AS LoginType,
       E.create_date AS LoginCreationDate,
       E.is_disabled AS IsLoginDisabled,
       E.permission AS PermissionName,
       E.grant_through AS PermissionGrantedThrough,
       COALESCE(T2.AccountName, T1.AccountName, E.name) AS AccountName,
       COALESCE(C1.DisplayName, C2.DisplayName, CASE WHEN E.type_desc = 'WINDOWS_GROUP' AND T2.AccountName IS NULL AND T1.AccountName IS NULL THEN 'No members' ELSE C3.DisplayName END) AS DisplayName
FROM explicit AS E
    LEFT OUTER JOIN #xpLogininfoOutput AS T1
        ON E.type_desc = 'WINDOWS_GROUP'
           AND E.name = T1.PermissionPath
    LEFT OUTER JOIN BLITZRESULTS.DBA_Rep.dbo.Staff AS C1
        ON RIGHT(T1.AccountName, 8) = C1.Name COLLATE DATABASE_DEFAULT
    LEFT OUTER JOIN BLITZRESULTS.DBA_Rep.dbo.Staff AS C2
        ON E.type_desc = 'WINDOWS_LOGIN'
           AND RIGHT(E.name, 8) = C2.Name COLLATE DATABASE_DEFAULT
    LEFT OUTER JOIN #xpLogininfoOutput AS T2
        ON E.type_desc = 'WINDOWS_GROUP'
           AND T1.AccountName = T2.PermissionPath
    LEFT OUTER JOIN BLITZRESULTS.DBA_Rep.dbo.Staff AS C3
        ON RIGHT(T2.AccountName, 8) = C3.Name COLLATE DATABASE_DEFAULT
WHERE E.type_desc NOT IN ( 'SERVER_ROLE' )
      AND E.name NOT IN ( 'sa', 'SQLDBO', 'SQLNETIQ' )
      AND E.name NOT LIKE '##%'
      AND E.name NOT LIKE 'NT SERVICE%'
      AND E.name NOT LIKE 'NT AUTHORITY%'
      AND E.name NOT LIKE 'BUILTIN%'
      AND E.permission <> 'CONNECT SQL'
	  --AND COALESCE(C1.DisplayName, C2.DisplayName, CASE WHEN E.type_desc = 'WINDOWS_GROUP' AND T2.AccountName IS NULL AND T1.AccountName IS NULL THEN 'No members' ELSE C3.DisplayName END) IS NULL
	  --AND (COALESCE(T2.AccountName, T1.AccountName, E.name) LIKE 'adm_%' OR COALESCE(T2.AccountName, T1.AccountName, E.name) LIKE '[0-9]%')
UNION ALL
SELECT DISTINCT
       F.name,
       F.type_desc,
       F.create_date,
       F.is_disabled,
       F.permission,
       F.grant_through,
       COALESCE(T2.AccountName, T1.AccountName, F.name) AS AccountName,
       COALESCE(C1.DisplayName, C2.DisplayName, CASE WHEN F.type_desc = 'WINDOWS_GROUP' AND T2.AccountName IS NULL AND T1.AccountName IS NULL THEN 'No members' ELSE C3.DisplayName END) AS DisplayName
FROM fixed AS F
    LEFT OUTER JOIN #xpLogininfoOutput AS T1
        ON F.type_desc = 'WINDOWS_GROUP'
           AND F.name = T1.PermissionPath
    LEFT OUTER JOIN BLITZRESULTS.DBA_Rep.dbo.Staff AS C1
        ON RIGHT(T1.AccountName, 8) = C1.Name COLLATE DATABASE_DEFAULT
    LEFT OUTER JOIN BLITZRESULTS.DBA_Rep.dbo.Staff AS C2
        ON F.type_desc = 'WINDOWS_LOGIN'
           AND RIGHT(F.name, 8) = C2.Name COLLATE DATABASE_DEFAULT
    LEFT OUTER JOIN #xpLogininfoOutput AS T2
        ON F.type_desc = 'WINDOWS_GROUP'
           AND T1.AccountName = T2.PermissionPath
    LEFT OUTER JOIN BLITZRESULTS.DBA_Rep.dbo.Staff AS C3
        ON RIGHT(T2.AccountName, 8) = C3.Name COLLATE DATABASE_DEFAULT
WHERE F.type_desc NOT IN ( 'SERVER_ROLE' )
      AND F.name NOT IN ( 'sa', 'SQLDBO', 'SQLNETIQ' )
      AND F.name NOT LIKE '##%'
      AND F.name NOT LIKE 'NT SERVICE%'
      AND F.name NOT LIKE 'NT AUTHORITY%'
      AND F.name NOT LIKE 'BUILTIN%'
      AND F.permission <> 'CONNECT SQL'
--	  AND COALESCE(C1.DisplayName, C2.DisplayName, CASE WHEN F.type_desc = 'WINDOWS_GROUP' AND T2.AccountName IS NULL AND T1.AccountName IS NULL THEN 'No members' ELSE C3.DisplayName END) IS NULL
--	  AND (COALESCE(T2.AccountName, T1.AccountName, F.name) LIKE 'adm_%' OR COALESCE(T2.AccountName, T1.AccountName, F.name) LIKE '[0-9]%')
ORDER BY E.name
OPTION (MAXRECURSION 10);

-- Section 2: Database-level permissions
CREATE TABLE #Info
(
    [database] sysname NOT NULL,
    username sysname NOT NULL,
    type_desc NVARCHAR(60) NOT NULL,
    create_date DATETIME NOT NULL,
    permission sysname NOT NULL,
    class_desc NVARCHAR(60) NULL,
    grant_through sysname NOT NULL
);

DECLARE @cmd VARCHAR(MAX);

SET @cmd = '';

SELECT @cmd
    = @cmd + 'INSERT #Info EXEC(''
USE ['        + name
      + ']
;WITH 
explicit AS (
   SELECT p.principal_id, p.name, p.type_desc, p.create_date,
         dbp.permission_name COLLATE SQL_Latin1_General_CP1_CI_AS permission,
		 dbp.class_desc + '''': '''' + SCHEMA_NAME(dbp.major_id) AS class_desc,
         CAST('''''''' AS SYSNAME) grant_through
   FROM sys.database_permissions dbp
   INNER JOIN sys.database_principals p ON dbp.grantee_principal_id = p.principal_id
   UNION ALL
   SELECT dp.principal_id, dp.name, dp.type_desc, dp.create_date, p.permission, NULL, p.name grant_through
   FROM sys.database_principals dp
   INNER JOIN sys.database_role_members rm ON rm.member_principal_id = dp.principal_id
   INNER JOIN explicit p ON p.principal_id = rm.role_principal_id
   ),
fixed AS (
   SELECT dp.principal_id, dp.name, dp.type_desc, dp.create_date, p.name permission, CAST(NULL AS NVARCHAR(60)) AS class_desc, CAST('''''''' AS SYSNAME) grant_through
   FROM sys.database_principals dp
   INNER JOIN sys.database_role_members rm ON rm.member_principal_id = dp.principal_id
   INNER JOIN sys.database_principals p ON p.principal_id = rm.role_principal_id
   UNION ALL
   SELECT dp.principal_id, dp.name, dp.type_desc, dp.create_date, p.permission, NULL, p.name grant_through
   FROM sys.database_principals dp
   INNER JOIN sys.database_role_members rm ON rm.member_principal_id = dp.principal_id
   INNER JOIN fixed p ON p.principal_id = rm.role_principal_id
   )
SELECT DB_NAME(), name, type_desc, create_date, permission, class_desc, grant_through
FROM explicit
WHERE type_desc NOT IN (''''DATABASE_ROLE'''')
  AND permission <> ''''CONNECT''''
  AND name <> ''''dbo''''
UNION ALL
SELECT DB_NAME(), name, type_desc, create_date, permission, class_desc, grant_through
FROM fixed
WHERE type_desc NOT IN (''''DATABASE_ROLE'''')
  AND permission <> ''''CONNECT''''
  AND name <> ''''dbo''''
OPTION (MAXRECURSION 10)
'');'
FROM sys.databases
WHERE state_desc = 'ONLINE'
  AND sys.fn_hadr_is_primary_replica ( name ) IS NULL OR sys.fn_hadr_is_primary_replica ( name ) = 1;

EXEC (@cmd);

SELECT DISTINCT
       I.[database] AS [Section 2: Database-level permissions - DatabaseName],
       I.username AS UserName,
       I.type_desc AS UserType,
       I.create_date AS UserCreationDate,
       I.permission AS PermissionName,
       I.class_desc AS PermissionScope,
       I.grant_through AS PermissionGrantedThrough,
       COALESCE(T2.AccountName, T1.AccountName, I.username) AS AccountName,
       COALESCE(C1.DisplayName, C2.DisplayName, CASE WHEN I.type_desc = 'WINDOWS_GROUP' AND T2.AccountName IS NULL THEN 'No members' ELSE C3.DisplayName END) AS DisplayName
FROM #Info AS I
    LEFT OUTER JOIN #xpLogininfoOutput AS T1
        ON I.type_desc = 'WINDOWS_GROUP'
           AND I.username = T1.PermissionPath
    LEFT OUTER JOIN BLITZRESULTS.DBA_Rep.dbo.Staff AS C1
        ON RIGHT(T1.AccountName, 8) = C1.Name COLLATE DATABASE_DEFAULT
    LEFT OUTER JOIN BLITZRESULTS.DBA_Rep.dbo.Staff AS C2
        ON I.type_desc = 'WINDOWS_USER'
           AND RIGHT(I.username, 8) = C2.Name COLLATE DATABASE_DEFAULT
    LEFT OUTER JOIN #xpLogininfoOutput AS T2
        ON I.type_desc = 'WINDOWS_GROUP'
           AND T1.AccountName = T2.PermissionPath
    LEFT OUTER JOIN BLITZRESULTS.DBA_Rep.dbo.Staff AS C3
        ON RIGHT(T2.AccountName, 8) = C3.Name COLLATE DATABASE_DEFAULT
WHERE I.username NOT IN ( 'dbo', 'guest', 'SQLDBO' )
      AND I.username NOT LIKE '##%'
      AND I.[database] NOT IN ( 'master', 'model', 'msdb', 'tempdb', 'SSISDB' )
      AND I.[database] NOT LIKE 'ReportServer%'
--	  AND COALESCE(C1.DisplayName, C2.DisplayName, CASE WHEN I.type_desc = 'WINDOWS_GROUP' AND T2.AccountName IS NULL THEN 'No members' ELSE C3.DisplayName END) IS NULL
--	  AND (COALESCE(T2.AccountName, T1.AccountName, I.username) LIKE 'adm_%' OR COALESCE(T2.AccountName, T1.AccountName, I.username) LIKE '[0-9]%')
ORDER BY I.[database],
         I.username;

-- Section 3: Object-level permissions
CREATE TABLE #rolemember_kk
(
    dbRole sysname NULL,
    MemberName sysname NULL,
    membersid VARBINARY(85) NULL
);

CREATE TABLE #ObjectLevelPermissions
(
    DatabaseName NVARCHAR(128) NULL,
    State NVARCHAR(60) NULL,
    PermissionName NVARCHAR(128) NULL,
    ObjectName sysname NULL,
    ObjectType NVARCHAR(60) NULL,
    Login NVARCHAR(256) NULL,
    DatabasePrincipalType NVARCHAR(60) NULL
);

CREATE TABLE #DatabaseRoles
(
    DatabaseName sysname NOT NULL,
	DatabaseRoleName sysname NOT NULL,
    DatabaseUserName sysname NOT NULL
);

DECLARE @command VARCHAR(MAX);
SELECT @command
    = '
TRUNCATE TABLE #rolemember_kk;
INSERT INTO #rolemember_kk 
	EXEC sp_helprolemember;

INSERT INTO #ObjectLevelPermissions
SELECT  ''?'' AS DatabaseName,
		perm.state_desc AS State,
		perm.permission_name AS PermissionName,
		SCHEMA_NAME(obj.schema_id) + ''.'' + obj.name
			+ CASE WHEN cl.column_id IS NULL THEN SPACE(0) ELSE ''('' + cl.name + '')'' END AS ObjectName,
		obj.type_desc AS ObjectType,
		USER_NAME(usr.principal_id) COLLATE DATABASE_DEFAULT AS Login,
		usr.type_desc AS DatabasePrincipalType
FROM    sys.database_permissions AS perm
        INNER JOIN sys.objects AS obj ON perm.major_id = obj.object_id
        INNER JOIN sys.database_principals AS usr ON perm.grantee_principal_id = usr.principal_id
        LEFT JOIN sys.columns AS cl ON cl.column_id = perm.minor_id
                                       AND cl.object_id = perm.major_id
WHERE USER_NAME(usr.principal_id) COLLATE DATABASE_DEFAULT NOT IN ( ''public'', ''guest'' )
  AND (usr.type_desc <> ''DATABASE_ROLE''
    OR (usr.type_desc = ''DATABASE_ROLE''
        AND USER_NAME(usr.principal_id) COLLATE DATABASE_DEFAULT IN ( SELECT DISTINCT dbRole FROM #rolemember_kk AS RM )));	-- Only database roles that have no members

INSERT INTO #DatabaseRoles
(
    DatabaseName,
	DatabaseRoleName,
    DatabaseUserName
)
	SELECT ''?'',
		   DP1.name,
		   ISNULL(DP2.name, ''No members'')
	FROM sys.database_role_members AS DRM
		RIGHT OUTER JOIN sys.database_principals AS DP1
			ON DRM.role_principal_id = DP1.principal_id
		LEFT OUTER JOIN sys.database_principals AS DP2
			ON DRM.member_principal_id = DP2.principal_id
	WHERE DP1.type = ''R'';';

EXEC dbo.sp_ineachdb @command = @command, @suppress_quotename = 1;

SELECT O.DatabaseName AS [Section 3: Object-level permissions - DatabaseName],
       O.State,
       O.PermissionName,
       O.ObjectName,
       O.ObjectType,
       O.Login AS LoginOrDatabaseRole,
       O.DatabasePrincipalType,
       COALESCE(T2.AccountName, T1.AccountName, dr.DatabaseUserName) AS AccountName,
       COALESCE(C1.DisplayName, C2.DisplayName, C4.DisplayName, CASE WHEN O.DatabasePrincipalType = 'WINDOWS_GROUP' AND T2.AccountName IS NULL AND T1.AccountName IS NULL THEN 'No members' ELSE C3.DisplayName END) AS DisplayName
FROM #ObjectLevelPermissions AS O
    LEFT OUTER JOIN #xpLogininfoOutput AS T1
        ON O.DatabasePrincipalType = 'WINDOWS_GROUP'
           AND O.Login = T1.PermissionPath
    LEFT OUTER JOIN BLITZRESULTS.DBA_Rep.dbo.Staff AS C1
        ON RIGHT(T1.AccountName, 8) = C1.Name COLLATE DATABASE_DEFAULT
    LEFT OUTER JOIN BLITZRESULTS.DBA_Rep.dbo.Staff AS C2
        ON O.DatabasePrincipalType = 'WINDOWS_USER'
           AND RIGHT(O.Login, 8) = C2.Name COLLATE DATABASE_DEFAULT
    LEFT OUTER JOIN #xpLogininfoOutput AS T2
        ON O.DatabasePrincipalType = 'WINDOWS_GROUP'
           AND T1.AccountName = T2.PermissionPath
    LEFT OUTER JOIN BLITZRESULTS.DBA_Rep.dbo.Staff AS C3
        ON RIGHT(T2.AccountName, 8) = C3.Name COLLATE DATABASE_DEFAULT
    LEFT OUTER JOIN #DatabaseRoles AS dr
        ON O.DatabasePrincipalType = 'DATABASE_ROLE'
           AND O.DatabaseName = dr.DatabaseName
		   AND O.Login = dr.DatabaseRoleName
    LEFT OUTER JOIN #xpLogininfoOutput AS T3
        ON O.DatabasePrincipalType = 'DATABASE_ROLE'
           AND dr.DatabaseUserName = T3.PermissionPath
    LEFT OUTER JOIN BLITZRESULTS.DBA_Rep.dbo.Staff AS C4
        ON RIGHT(T3.AccountName, 8) = C4.Name COLLATE DATABASE_DEFAULT
WHERE O.DatabaseName NOT IN ( 'msdb', 'SSISDB' )
      AND O.DatabaseName NOT LIKE 'ReportServer%'
      AND O.ObjectType <> 'SYSTEM_TABLE'
--	  AND COALESCE(C1.DisplayName, C2.DisplayName, C4.DisplayName, CASE WHEN O.DatabasePrincipalType = 'WINDOWS_GROUP' AND T2.AccountName IS NULL AND T1.AccountName IS NULL THEN 'No members' ELSE C3.DisplayName END) IS NULL
--	  AND (COALESCE(T2.AccountName, T1.AccountName, dr.DatabaseUserName) LIKE 'adm_%' OR COALESCE(T2.AccountName, T1.AccountName, dr.DatabaseUserName) LIKE '[0-9]%')
ORDER BY O.DatabaseName,
         O.State,
         O.PermissionName,
         O.ObjectName,
         O.Login;

DROP TABLE #rolemember_kk;
DROP TABLE #ObjectLevelPermissions;
DROP TABLE #xpLogininfoOutput;
DROP TABLE #Info;
DROP TABLE #DatabaseRoles;
GO
