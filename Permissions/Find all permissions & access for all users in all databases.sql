-- Find all permissions & access for all users in all databases
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script displays 3 sections of permissions for the instance: instance-level, database-level and object-level.
-- From https://www.mssqltips.com/sqlservertip/2048/auditing-sql-server-permissions-and-roles-for-the-server/

USE [master];
GO

-- Section 1: Instance-level permissions
SELECT SP1.[name] AS [Section 1: InstancePermissions - Login],
       SP1.type_desc AS PrincipalType,
       SP1.create_date AS CreateDate,
       SP1.is_disabled AS IsDisabled,
       'Role: ' + SP2.[name] COLLATE DATABASE_DEFAULT AS InstancePermission
FROM sys.server_principals SP1
    JOIN sys.server_role_members SRM
        ON SP1.principal_id = SRM.member_principal_id
    JOIN sys.server_principals SP2
        ON SRM.role_principal_id = SP2.principal_id
WHERE SP1.[name] NOT LIKE 'NT SERVICE\%'
      AND SP1.[name] NOT IN ( 'sa', 'NT AUTHORITY\SYSTEM' )
UNION ALL
SELECT SP.[name] AS Login,
       SP.type_desc,
       SP.create_date,
       SP.is_disabled,
       SPerm.state_desc + ' ' + SPerm.permission_name COLLATE DATABASE_DEFAULT AS InstancePermission
FROM sys.server_principals SP
    JOIN sys.server_permissions SPerm
        ON SP.principal_id = SPerm.grantee_principal_id
WHERE SPerm.state_desc + ' ' + SPerm.permission_name COLLATE DATABASE_DEFAULT NOT IN ( 'GRANT CONNECT SQL',
                                                                                       'GRANT CONNECT'
                                                                                     )
      AND SP.[name] NOT LIKE '##%'
      AND SP.[name] NOT LIKE 'NT SERVICE\%'
      AND SP.[name] NOT IN ( 'public', 'NT AUTHORITY\SYSTEM' )
ORDER BY SP1.[name],
         InstancePermission;
GO

-- Section 2: Database-level permissions - pivoted
-- From http://stackoverflow.com/questions/7048839/sql-server-query-to-find-all-permissions-access-for-all-users-in-a-database
BEGIN TRY
    IF EXISTS
    (
        SELECT *
        FROM tempdb.dbo.sysobjects
        WHERE id = OBJECT_ID(N'[tempdb].dbo.[#permission]')
    )
        DROP TABLE #permission;
    IF EXISTS
    (
        SELECT *
        FROM tempdb.dbo.sysobjects
        WHERE id = OBJECT_ID(N'[tempdb].dbo.[#UserRoles_kk]')
    )
        DROP TABLE #UserRoles_kk;
    IF EXISTS
    (
        SELECT *
        FROM tempdb.dbo.sysobjects
        WHERE id = OBJECT_ID(N'[tempdb].dbo.[#rolemember_kk]')
    )
        DROP TABLE #rolemember_kk;
    IF EXISTS
    (
        SELECT *
        FROM tempdb.dbo.sysobjects
        WHERE id = OBJECT_ID(N'[tempdb].dbo.[##db_name]')
    )
        DROP TABLE ##db_name;

    DECLARE @db_name sysname,
            @sql_text VARCHAR(MAX);

    SET @sql_text = 'CREATE TABLE ##db_name
    (
		[Section 2: DatabasePermissions pivoted - Login] SYSNAME
        ,';

    DECLARE cursDBs CURSOR LOCAL FAST_FORWARD FOR
    SELECT [name]
    FROM sys.databases
    WHERE state_desc = 'ONLINE'
    ORDER BY [name];

    OPEN cursDBs;

    FETCH NEXT FROM cursDBs
    INTO @db_name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql_text = @sql_text + QUOTENAME(@db_name) + ' SYSNAME NULL
        ,';
        FETCH NEXT FROM cursDBs
        INTO @db_name;
    END;

    CLOSE cursDBs;

    SET @sql_text = @sql_text + 'IsSysAdminLogin CHAR(1)
        ,IsEmptyRow CHAR(1)
    )';

    --PRINT @sql_text
    EXEC (@sql_text);

    DEALLOCATE cursDBs;

    DECLARE @UserName sysname;

    CREATE TABLE #permission
    (
        [Login] sysname NULL,
        databasename sysname NULL,
        [role] sysname NULL
    );

    DECLARE cursSysSrvPrinName CURSOR LOCAL FAST_FORWARD FOR
    SELECT [name]
    FROM sys.server_principals
    WHERE [type] IN ( 'S', 'U', 'G' )
          AND principal_id > 4
          AND [name] NOT LIKE '##%'
    ORDER BY [name];

    OPEN cursSysSrvPrinName;

    FETCH NEXT FROM cursSysSrvPrinName
    INTO @UserName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        CREATE TABLE #UserRoles_kk
        (
            databasename sysname NULL,
            [role] sysname NULL
        );

        CREATE TABLE #rolemember_kk
        (
            dbRole sysname NULL,
            MemberName sysname NULL,
            membersid VARBINARY(85) NULL
        );

        DECLARE cursDatabases CURSOR LOCAL FAST_FORWARD FOR
        SELECT [name]
        FROM sys.databases
        WHERE state_desc = 'ONLINE'
        ORDER BY [name];

        OPEN cursDatabases;

        DECLARE @DBN sysname,
                @sqlText NVARCHAR(MAX);

        FETCH NEXT FROM cursDatabases
        INTO @DBN;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @sqlText
                = N'USE ' + QUOTENAME(@DBN)
                  + N';
    TRUNCATE TABLE #rolemember_kk;

    INSERT INTO #rolemember_kk 
    EXEC sp_helprolemember;

    INSERT INTO #UserRoles_kk
    (databasename,[role])
    SELECT db_name(),dbRole
    FROM #rolemember_kk
    WHERE MemberName = ''' + @UserName + N''';
    '       ;

            --PRINT @sqlText ;

            EXEC sp_executesql @stmt = @sqlText;

            FETCH NEXT FROM cursDatabases
            INTO @DBN;
        END;

        CLOSE cursDatabases;

        DEALLOCATE cursDatabases;

        INSERT INTO #permission
        (
            Login,
            databasename,
            role
        )
        SELECT @UserName 'user',
               b.name,
               u.[role]
        FROM sys.sysdatabases b
            LEFT JOIN #UserRoles_kk u
                ON QUOTENAME(u.databasename) = QUOTENAME(b.name)
        ORDER BY 1;

        DROP TABLE #UserRoles_kk;
        DROP TABLE #rolemember_kk;

        FETCH NEXT FROM cursSysSrvPrinName
        INTO @UserName;
    END;

    CLOSE cursSysSrvPrinName;

    DEALLOCATE cursSysSrvPrinName;

    TRUNCATE TABLE ##db_name;

    DECLARE @d1 sysname,
            @d2 sysname,
            @d3 sysname,
            @ss VARCHAR(200);

    DECLARE cursPermisTable CURSOR LOCAL FAST_FORWARD FOR
    SELECT [Login],
           databasename,
           role
    FROM #permission
    ORDER BY databasename DESC;

    OPEN cursPermisTable;

    FETCH NEXT FROM cursPermisTable
    INTO @d1,
         @d2,
         @d3;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS
        (
            SELECT 1
            FROM ##db_name
            WHERE [Section 2: DatabasePermissions pivoted - Login] = @d1
        )
        BEGIN
            SET @ss = 'INSERT INTO ##db_name([Section 2: DatabasePermissions pivoted - Login]) VALUES (''' + @d1 + ''')';
            EXEC (@ss);
            SET @ss
                = 'UPDATE ##db_name SET ' + @d2 + ' = ''' + @d3 + ''' WHERE [Section 2: DatabasePermissions pivoted - Login] = '''
                  + @d1 + '''';
            EXEC (@ss);
        END;
        ELSE
        BEGIN
            DECLARE @var NVARCHAR(MAX),
                    @ParmDefinition NVARCHAR(MAX),
                    @var1 NVARCHAR(MAX);

            SET @var
                = N'SELECT @var1 = ' + QUOTENAME(@d2)
                  + N' FROM ##db_name WHERE [Section 2: DatabasePermissions pivoted - Login] = ''' + @d1 + N'''';
            SET @ParmDefinition = N'@var1 NVARCHAR(600) OUTPUT ';
            EXECUTE sp_executesql @stmt = @var,
                                  @params = @ParmDefinition,
                                  @var1 = @var1 OUTPUT;

            SET @var1 = ISNULL(@var1, ' ');
            SET @var
                = N'  UPDATE ##db_name SET ' + QUOTENAME(@d2) + N'=''' + @var1 + N' ' + @d3
                  + N''' WHERE [Section 2: DatabasePermissions pivoted - Login] = ''' + @d1 + N'''  ';
            EXEC (@var);
        END;

        FETCH NEXT FROM cursPermisTable
        INTO @d1,
             @d2,
             @d3;
    END;

    CLOSE cursPermisTable;

    DEALLOCATE cursPermisTable;

    UPDATE ##db_name
    SET IsSysAdminLogin = 'Y'
    FROM ##db_name TT
        INNER JOIN dbo.syslogins SL
            ON TT.[Section 2: DatabasePermissions pivoted - Login] = SL.[name]
    WHERE SL.sysadmin = 1;

    DECLARE cursDNamesAsColumns CURSOR LOCAL FAST_FORWARD FOR
    SELECT [name]
    FROM tempdb.sys.columns
    WHERE object_id = OBJECT_ID('tempdb..##db_name')
          AND [name] NOT IN ( 'Login', 'IsEmptyRow', 'IsSysAdminLogin', 'Section 2: DatabasePermissions - InstanceName' )
    ORDER BY [name];

    OPEN cursDNamesAsColumns;

    DECLARE @ColN sysname,
            @tSQLText NVARCHAR(MAX);

    FETCH NEXT FROM cursDNamesAsColumns
    INTO @ColN;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @tSQLText = N'UPDATE ##db_name SET
IsEmptyRow = ''N''
WHERE IsEmptyRow IS NULL
AND ' + QUOTENAME(@ColN) + N' IS NOT NULL
;
'       ;
        --PRINT @tSQLText ;

        EXEC sp_executesql @tSQLText;

        FETCH NEXT FROM cursDNamesAsColumns
        INTO @ColN;
    END;

    CLOSE cursDNamesAsColumns;

    DEALLOCATE cursDNamesAsColumns;

    UPDATE ##db_name
    SET IsEmptyRow = 'Y'
    WHERE IsEmptyRow IS NULL;

    UPDATE ##db_name
    SET IsSysAdminLogin = 'N'
    FROM ##db_name TT
        INNER JOIN dbo.syslogins SL
            ON TT.[Section 2: DatabasePermissions pivoted - Login] = SL.[name]
    WHERE SL.sysadmin = 0;

    SELECT *
    FROM ##db_name
    WHERE IsEmptyRow = 'N'
          AND [Section 2: DatabasePermissions pivoted - Login] NOT LIKE 'NT SERVICE\%'
    ORDER BY [Section 2: DatabasePermissions pivoted - Login];

    DROP TABLE ##db_name;
    DROP TABLE #permission;
END TRY
BEGIN CATCH
    DECLARE @cursDBs_Status INT,
            @cursSysSrvPrinName_Status INT,
            @cursDatabases_Status INT,
            @cursPermisTable_Status INT,
            @cursDNamesAsColumns_Status INT;
    SELECT @cursDBs_Status = CURSOR_STATUS('GLOBAL', 'cursDBs'),
           @cursSysSrvPrinName_Status = CURSOR_STATUS('GLOBAL', 'cursSysSrvPrinName'),
           @cursDatabases_Status = CURSOR_STATUS('GLOBAL', 'cursDatabases'),
           @cursPermisTable_Status = CURSOR_STATUS('GLOBAL', 'cursPermisTable'),
           @cursDNamesAsColumns_Status = CURSOR_STATUS('GLOBAL', 'cursDNamesAsColumns');
    IF @cursDBs_Status > -2
    BEGIN
        CLOSE cursDBs;
        DEALLOCATE cursDBs;
    END;
    IF @cursSysSrvPrinName_Status > -2
    BEGIN
        CLOSE cursSysSrvPrinName;
        DEALLOCATE cursSysSrvPrinName;
    END;
    IF @cursDatabases_Status > -2
    BEGIN
        CLOSE cursDatabases;
        DEALLOCATE cursDatabases;
    END;
    IF @cursPermisTable_Status > -2
    BEGIN
        CLOSE cursPermisTable;
        DEALLOCATE cursPermisTable;
    END;
    IF @cursDNamesAsColumns_Status > -2
    BEGIN
        CLOSE cursDNamesAsColumns;
        DEALLOCATE cursDNamesAsColumns;
    END;
    SELECT ErrorNum = ERROR_NUMBER(),
           ErrorMsg = ERROR_MESSAGE(),
           LineNumber = ERROR_LINE();
END CATCH;
GO

-- Section 3: Database-level permissions - unpivoted
CREATE TABLE #DatabasePermissionsUnpivoted
( DatabaseName sysname NOT NULL,
  PrincipalName sysname NOT NULL,
  PrincipalType VARCHAR(20) NOT NULL,
  CreateDate DATETIME2 NOT NULL,
  PermissionName VARCHAR(100) NOT NULL );

INSERT INTO #DatabasePermissionsUnpivoted (DatabaseName, PrincipalName, PrincipalType, CreateDate, PermissionName)
EXEC sp_ineachdb @command = '
SELECT DB_NAME(), dp.name, dp.type_desc,
    dp.create_date, dpe.permission_name
FROM sys.database_principals AS dp
INNER JOIN sys.database_permissions AS dpe  
    ON dpe.grantee_principal_id = dp.principal_id  
WHERE dp.name NOT IN (''public'', ''dbo'', ''guest'', ''sys'', ''INFORMATION_SCHEMA'' )
AND NOT (dp.type_desc = ''DATABASE_ROLE'' AND dp.is_fixed_role = 1);
', @user_only = 1, @exclude_list = 'SSISDB';
GO

SELECT DISTINCT DatabaseName AS 'Section 3: DatabasePermissions unpivoted - DatabaseName',
       PrincipalName,
       PrincipalType,
       CreateDate,
       PermissionName
FROM #DatabasePermissionsUnpivoted
ORDER BY DatabaseName, PrincipalName, PermissionName;

DROP TABLE #DatabasePermissionsUnpivoted;

-- Section 4: Object-level permissions
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
		QUOTENAME(SCHEMA_NAME(obj.schema_id)) + ''.'' + QUOTENAME(obj.name) 
			+ CASE WHEN cl.column_id IS NULL THEN SPACE(0) ELSE ''('' + QUOTENAME(cl.name) + '')'' END AS ObjectName,
		obj.type_desc AS ObjectType,
		QUOTENAME(USER_NAME(usr.principal_id)) COLLATE DATABASE_DEFAULT AS Login,
		usr.type_desc AS DatabasePrincipalType
FROM    sys.database_permissions AS perm
        INNER JOIN sys.objects AS obj ON perm.major_id = obj.[object_id]
        INNER JOIN sys.database_principals AS usr ON perm.grantee_principal_id = usr.principal_id
        LEFT JOIN sys.columns AS cl ON cl.column_id = perm.minor_id
                                       AND cl.[object_id] = perm.major_id
WHERE QUOTENAME(USER_NAME(usr.principal_id)) COLLATE DATABASE_DEFAULT NOT IN ( ''[public]'', ''[guest]'' )
  AND (usr.type_desc <> ''DATABASE_ROLE''
    OR (usr.type_desc = ''DATABASE_ROLE''
        AND QUOTENAME(USER_NAME(usr.principal_id)) COLLATE DATABASE_DEFAULT IN ( SELECT DISTINCT QUOTENAME(dbRole) FROM #rolemember_kk AS RM )));	-- Only database roles that have no members
';

EXEC dbo.sp_ineachdb @command = @command;

SELECT DatabaseName AS [Section 4: ObjectLevelPermissions - DatabaseName],
       State,
       PermissionName,
       ObjectName,
       ObjectType,
       Login,
       DatabasePrincipalType
FROM #ObjectLevelPermissions
WHERE DatabaseName NOT IN ( '[msdb]', '[SSISDB]' )
      AND DatabaseName NOT LIKE '\[ReportServer%' ESCAPE '\'
      AND ObjectType <> 'SYSTEM_TABLE'
ORDER BY DatabaseName,
         State,
         PermissionName,
         ObjectName,
         Login;

DROP TABLE #rolemember_kk;
DROP TABLE #ObjectLevelPermissions;
GO
