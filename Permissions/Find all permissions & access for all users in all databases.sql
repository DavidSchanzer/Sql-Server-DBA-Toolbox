USE [master];
GO

-- Section 1: Instance-level permissions
-- From https://www.mssqltips.com/sqlservertip/2048/auditing-sql-server-permissions-and-roles-for-the-server/
SELECT  @@SERVERNAME AS 'Section 1: InstancePermissions - InstanceName', 'Role: ' + SP2.[name] COLLATE DATABASE_DEFAULT AS 'InstancePermission', SP1.[name] AS 'Login'
FROM    sys.server_principals SP1
        JOIN sys.server_role_members SRM ON SP1.principal_id = SRM.member_principal_id
        JOIN sys.server_principals SP2 ON SRM.role_principal_id = SP2.principal_id
UNION ALL
SELECT  @@SERVERNAME AS 'Section 1: InstancePermissions - InstanceName', SPerm.state_desc + ' ' + SPerm.permission_name COLLATE DATABASE_DEFAULT AS 'InstancePermission', SP.[name] AS 'Login'
FROM    sys.server_principals SP
        JOIN sys.server_permissions SPerm ON SP.principal_id = SPerm.grantee_principal_id
WHERE   SPerm.state_desc + ' ' + SPerm.permission_name COLLATE DATABASE_DEFAULT NOT IN ( 'GRANT CONNECT SQL', 'GRANT CONNECT' )
        AND SP.[name] NOT LIKE '##%'
        AND SP.[name] NOT IN ( 'public', 'NT AUTHORITY\SYSTEM' )
ORDER BY [Section 1: InstancePermissions - InstanceName], InstancePermission, [Login]; 
GO

-- Section 2: Database-level permissions
-- From http://stackoverflow.com/questions/7048839/sql-server-query-to-find-all-permissions-access-for-all-users-in-a-database
BEGIN TRY
    IF EXISTS ( SELECT  *
                FROM    tempdb.dbo.sysobjects
                WHERE   id = OBJECT_ID(N'[tempdb].dbo.[#permission]') )
        DROP TABLE #permission;
    IF EXISTS ( SELECT  *
                FROM    tempdb.dbo.sysobjects
                WHERE   id = OBJECT_ID(N'[tempdb].dbo.[#UserRoles_kk]') )
        DROP TABLE #UserRoles_kk;
    IF EXISTS ( SELECT  *
                FROM    tempdb.dbo.sysobjects
                WHERE   id = OBJECT_ID(N'[tempdb].dbo.[#rolemember_kk]') )
        DROP TABLE #rolemember_kk;
    IF EXISTS ( SELECT  *
                FROM    tempdb.dbo.sysobjects
                WHERE   id = OBJECT_ID(N'[tempdb].dbo.[##db_name]') )
        DROP TABLE ##db_name;
    DECLARE @db_name VARCHAR(4000),
        @sql_text VARCHAR(MAX);
    SET @sql_text = 'CREATE TABLE ##db_name
    (
		[Section 2: DatabaseRoles - InstanceName] VARCHAR(4000) DEFAULT @@ServerName,
		[Login] VARCHAR(4000)
        ,';
    DECLARE cursDBs CURSOR
    FOR
        SELECT  [name]
        FROM    sys.databases
		WHERE state_desc = 'ONLINE'
        ORDER BY [name];
    OPEN cursDBs;
    FETCH NEXT FROM cursDBs INTO @db_name; 
    WHILE @@FETCH_STATUS = 0
        BEGIN 
            SET @sql_text = @sql_text + QUOTENAME(@db_name) + ' VARCHAR(4000)
        ,'; 
            FETCH NEXT FROM cursDBs INTO @db_name; 
        END; 
    CLOSE cursDBs;
    SET @sql_text = @sql_text + 'IsSysAdminLogin CHAR(1)
        ,IsEmptyRow CHAR(1)
    )'; 

    --PRINT @sql_text
    EXEC (@sql_text);
    DEALLOCATE cursDBs;
    DECLARE @RoleName VARCHAR(4000),
        @UserName VARCHAR(4000);
    CREATE TABLE #permission
        (
          [Login] VARCHAR(4000),
          databasename VARCHAR(4000),
          [role] VARCHAR(4000)
        );
    DECLARE cursSysSrvPrinName CURSOR
    FOR
        SELECT  [name]
        FROM    sys.server_principals
        WHERE   [type] IN ( 'S', 'U', 'G' )
                AND principal_id > 4
                AND [name] NOT LIKE '##%'
        ORDER BY [name];
    OPEN cursSysSrvPrinName;
    FETCH NEXT FROM cursSysSrvPrinName INTO @UserName; 
    WHILE @@FETCH_STATUS = 0
        BEGIN 
            CREATE TABLE #UserRoles_kk
                (
                  databasename VARCHAR(4000),
                  [role] VARCHAR(4000)
                );
            CREATE TABLE #rolemember_kk
                (
                  dbRole VARCHAR(4000),
                  MemberName VARCHAR(4000),
                  membersid VARBINARY(2048)
                );
            DECLARE cursDatabases CURSOR FAST_FORWARD LOCAL
            FOR
                SELECT  [name]
                FROM    sys.databases
				WHERE state_desc = 'ONLINE'
                ORDER BY [name];
            OPEN cursDatabases;
            DECLARE @DBN VARCHAR(4000),
                @sqlText NVARCHAR(MAX);
            FETCH NEXT FROM cursDatabases INTO @DBN;
            WHILE @@FETCH_STATUS = 0
                BEGIN
                    SET @sqlText = N'USE ' + QUOTENAME(@DBN) + ';
    TRUNCATE TABLE #rolemember_kk 
    INSERT INTO #rolemember_kk 
    EXEC sp_helprolemember 
    INSERT INTO #UserRoles_kk
    (databasename,[role])
    SELECT db_name(),dbRole
    FROM #rolemember_kk
    WHERE MemberName = ''' + @UserName + '''
    ';

            --PRINT @sqlText ;
                    EXEC sp_executesql @sqlText;
                    FETCH NEXT FROM cursDatabases INTO @DBN;
                END;
            CLOSE cursDatabases;
            DEALLOCATE cursDatabases;
            INSERT  INTO #permission
                    SELECT  @UserName 'user', b.name, u.[role]
                    FROM    sys.sysdatabases b
                            LEFT JOIN #UserRoles_kk u ON QUOTENAME(u.databasename) = QUOTENAME(b.name)
                    ORDER  BY 1;
            DROP TABLE #UserRoles_kk; 
            DROP TABLE #rolemember_kk;
            FETCH NEXT FROM cursSysSrvPrinName INTO @UserName; 
        END; 
    CLOSE cursSysSrvPrinName;
    DEALLOCATE cursSysSrvPrinName;
    TRUNCATE TABLE ##db_name;
    DECLARE @d1 VARCHAR(4000),
        @d2 VARCHAR(4000),
        @d3 VARCHAR(4000),
        @ss VARCHAR(4000);
    DECLARE cursPermisTable CURSOR
    FOR
        SELECT  [Login], databasename, role
        FROM    #permission
        ORDER BY 2 DESC;
    OPEN cursPermisTable;
    FETCH NEXT FROM cursPermisTable INTO @d1, @d2, @d3;
    WHILE @@FETCH_STATUS = 0
        BEGIN 
            IF NOT EXISTS ( SELECT  1
                            FROM    ##db_name
                            WHERE   [Login] = @d1 )
                BEGIN 
                    SET @ss = 'INSERT INTO ##db_name([Login]) VALUES (''' + @d1 + ''')'; 
                    EXEC (@ss);
                    SET @ss = 'UPDATE ##db_name SET ' + @d2 + ' = ''' + @d3 + ''' WHERE [Login] = ''' + @d1 + ''''; 
                    EXEC (@ss);
                END; 
            ELSE
                BEGIN 
                    DECLARE @var NVARCHAR(MAX),
                        @ParmDefinition NVARCHAR(MAX),
                        @var1 NVARCHAR(MAX);
                    SET @var = N'SELECT @var1 = ' + QUOTENAME(@d2) + ' FROM ##db_name WHERE [Login] = ''' + @d1 + ''''; 
                    SET @ParmDefinition = N'@var1 NVARCHAR(600) OUTPUT '; 
                    EXECUTE sp_executesql @var, @ParmDefinition, @var1 = @var1 OUTPUT;
                    SET @var1 = ISNULL(@var1, ' ');
                    SET @var = '  UPDATE ##db_name SET ' + QUOTENAME(@d2) + '=''' + @var1 + ' ' + @d3 + ''' WHERE [Login] = ''' + @d1
                        + '''  ';
                    EXEC (@var);
                END;
            FETCH NEXT FROM cursPermisTable INTO @d1, @d2, @d3;
        END; 
    CLOSE cursPermisTable;
    DEALLOCATE cursPermisTable;
    UPDATE  ##db_name
    SET     IsSysAdminLogin = 'Y'
    FROM    ##db_name TT
            INNER JOIN dbo.syslogins SL ON TT.[Login] = SL.[name]
    WHERE   SL.sysadmin = 1;
    DECLARE cursDNamesAsColumns CURSOR FAST_FORWARD LOCAL
    FOR
        SELECT  [name]
        FROM    tempdb.sys.columns
        WHERE   object_id = OBJECT_ID('tempdb..##db_name')
                AND [name] NOT IN ( '[Login]', 'IsEmptyRow' )
        ORDER BY [name];
    OPEN cursDNamesAsColumns;
    DECLARE @ColN VARCHAR(4000),
        @tSQLText NVARCHAR(MAX);
    FETCH NEXT FROM cursDNamesAsColumns INTO @ColN;
    WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @tSQLText = N'UPDATE ##db_name SET
IsEmptyRow = ''N''
WHERE IsEmptyRow IS NULL
AND ' + QUOTENAME(@ColN) + ' IS NOT NULL
;
';

        --PRINT @tSQLText ;
            EXEC sp_executesql @tSQLText;
            FETCH NEXT FROM cursDNamesAsColumns INTO @ColN;
        END;
    CLOSE cursDNamesAsColumns;
    DEALLOCATE cursDNamesAsColumns;
    UPDATE  ##db_name
    SET     IsEmptyRow = 'Y'
    WHERE   IsEmptyRow IS NULL;
    UPDATE  ##db_name
    SET     IsSysAdminLogin = 'N'
    FROM    ##db_name TT
            INNER JOIN dbo.syslogins SL ON TT.[Login] = SL.[name]
    WHERE   SL.sysadmin = 0;
    SELECT  *
    FROM    ##db_name;
    DROP TABLE ##db_name;
    DROP TABLE #permission;
END TRY
BEGIN CATCH
    DECLARE @cursDBs_Status INT,
        @cursSysSrvPrinName_Status INT,
        @cursDatabases_Status INT,
        @cursPermisTable_Status INT,
        @cursDNamesAsColumns_Status INT;
    SELECT  @cursDBs_Status = CURSOR_STATUS('GLOBAL', 'cursDBs'), @cursSysSrvPrinName_Status = CURSOR_STATUS('GLOBAL', 'cursSysSrvPrinName'),
            @cursDatabases_Status = CURSOR_STATUS('GLOBAL', 'cursDatabases'), @cursPermisTable_Status = CURSOR_STATUS('GLOBAL', 'cursPermisTable'),
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
    SELECT  ErrorNum = ERROR_NUMBER(), ErrorMsg = ERROR_MESSAGE();
END CATCH;
GO

-- Section 3: Object-level permissions
DECLARE @command VARCHAR(MAX);
SELECT  @command = '
USE [?]; 
SELECT  ''?'' AS DatabaseName,
		perm.state_desc AS State,
		perm.permission_name AS PermissionName,
		QUOTENAME(SCHEMA_NAME(obj.schema_id)) + ''.'' + QUOTENAME(obj.name) 
			+ CASE WHEN cl.column_id IS NULL THEN SPACE(0) ELSE ''('' + QUOTENAME(cl.name) + '')'' END AS ObjectName,
		QUOTENAME(USER_NAME(usr.principal_id)) COLLATE DATABASE_DEFAULT AS Login
FROM    sys.database_permissions AS perm
        INNER JOIN sys.objects AS obj ON perm.major_id = obj.[object_id]
        INNER JOIN sys.database_principals AS usr ON perm.grantee_principal_id = usr.principal_id
        LEFT JOIN sys.columns AS cl ON cl.column_id = perm.minor_id
                                       AND cl.[object_id] = perm.major_id
WHERE QUOTENAME(USER_NAME(usr.principal_id)) COLLATE DATABASE_DEFAULT NOT IN ( ''[public]'', ''[guest]'' );
';

DECLARE @ObjectLevelPermissions TABLE
    (
      DatabaseName VARCHAR(50),
      State VARCHAR(10),
      PermissionName VARCHAR(4000),
      ObjectName VARCHAR(4000),
      Login VARCHAR(4000)
    );

INSERT  INTO @ObjectLevelPermissions
        EXEC master.dbo.sp_MSforeachdb @command;

SELECT  @@SERVERNAME AS [Section 3: ObjectLevelPermissions - InstanceName], DatabaseName, State, PermissionName, ObjectName, Login
FROM    @ObjectLevelPermissions
WHERE   DatabaseName != 'msdb'
ORDER BY DatabaseName, State, PermissionName, ObjectName, Login;
GO
