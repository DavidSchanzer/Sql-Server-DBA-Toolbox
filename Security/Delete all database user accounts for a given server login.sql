-- Delete all database user accounts for a given server login
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script deletes (drops) all database level user accounts for a given server login from all databases on a database server. This will
-- drop users even if they have a different name from the server login, so long as the two are associated. This will not drop users from a
-- database where there are schemas/roles owned by the user.

/*===================================================================================================
	2013/07/15 hakim.ali@SQLzen.com
	From: http://www.sqlservercentral.com/scripts/User/100743/

	SQL Server 2005 and higher.
=====================================================================================================*/
USE [master];
GO

--------------------------------------------------------------------------------------
-- Set the login name here for which you want to delete all database user accounts.
DECLARE @LoginName NVARCHAR(200);
SET @LoginName = N'LOGIN_NAME_HERE';
--------------------------------------------------------------------------------------

DECLARE @counter INT;
DECLARE @sql NVARCHAR(1000);
DECLARE @dbname NVARCHAR(200);

-- To allow for repeated running of this script in one session (for separate logins).
BEGIN TRY
    DROP TABLE #DBUsers;
END TRY
BEGIN CATCH
END CATCH;

----------------------------------------------------------
-- Temp table to hold database user names for the login.
----------------------------------------------------------
CREATE TABLE #DBUsers
(
    ID INT IDENTITY(1, 1),
    LoginName VARCHAR(200) NOT NULL,
    DB VARCHAR(200) NOT NULL,
    UserName VARCHAR(200) NULL,
    Deleted BIT NOT NULL
);

-- Add all user databases.
INSERT INTO #DBUsers
(
    LoginName,
    DB,
    Deleted
)
SELECT @LoginName,
       name,
       1
FROM sys.databases
WHERE name NOT IN ( 'master', 'tempdb', 'model', 'msdb' )
      AND is_read_only = 0
      AND [state] = 0 -- online
ORDER BY name;

----------------------------------------------------------
-- Add database level users (if they exist) for the login.
----------------------------------------------------------
SET @counter =
(
    SELECT MIN(ID)FROM #DBUsers
);

WHILE EXISTS (SELECT 1 FROM #DBUsers WHERE ID >= @counter)
BEGIN
    SET @dbname =
    (
        SELECT DB FROM #DBUsers WHERE ID = @counter
    );
    SET @sql
        = N'
	update		temp
	set			temp.UserName = users.name
	from		sys.server_principals						as logins
	inner join	[' + @dbname
          + N'].sys.database_principals	as users
				on users.sid = logins.sid
				and logins.name = ''' + @LoginName + N'''
	inner join	#DBUsers									as temp
				on temp.DB = ''' + @dbname + N'''';

    EXEC sys.sp_executesql @stmt = @sql;

    SET @counter = @counter + 1;
END;

-- Don't need databases where a login-corresponding user was not found.
DELETE #DBUsers
WHERE UserName IS NULL;

----------------------------------------------------------
-- Now drop the users.
----------------------------------------------------------
SET @counter =
(
    SELECT MIN(ID)FROM #DBUsers
);

WHILE EXISTS (SELECT 1 FROM #DBUsers WHERE ID >= @counter)
BEGIN
    SELECT @sql = N'use [' + DB + N']; drop user [' + UserName + N']'
    FROM #DBUsers
    WHERE ID = @counter;

    --select @sql
    BEGIN TRY
        EXEC sys.sp_executesql @stmt = @sql;
    END TRY
    BEGIN CATCH
    END CATCH;
    SET @counter = @counter + 1;
END;

----------------------------------------------------------
-- Report on which users were/were not dropped.
----------------------------------------------------------
SET @counter =
(
    SELECT MIN(ID)FROM #DBUsers
);

WHILE EXISTS (SELECT 1 FROM #DBUsers WHERE ID >= @counter)
BEGIN
    SET @dbname =
    (
        SELECT DB FROM #DBUsers WHERE ID = @counter
    );
    SET @sql
        = N'
	update		temp
	set			temp.Deleted = 0
	from		sys.server_principals						as logins
	inner join	[' + @dbname
          + N'].sys.database_principals	as users
				on users.sid = logins.sid
				and logins.name = ''' + @LoginName + N'''
	inner join	#DBUsers									as temp
				on temp.DB = ''' + @dbname + N'''';

    EXEC sys.sp_executesql @stmt = @sql;

    SET @counter = @counter + 1;
END;

-- This shows the users that were/were not dropped, and the database they belong to.
IF EXISTS (SELECT 1 FROM #DBUsers)
BEGIN
    SELECT LoginName,
           [Database] = DB,
           UserName = UserName,
           Deleted = CASE Deleted
                         WHEN 1 THEN
                             'Yes'
                         ELSE
                             'No !!!!!!'
                     END
    FROM #DBUsers
    ORDER BY DB;
END;
ELSE
BEGIN
    SELECT [No Users Found] = 'No database-level users found on any database for the login "' + @LoginName + '".';
END;

/*===================================================================================================
Not automatically dropping the login. If there are database level users that were not dropped, 
dropping the login will create orphaned users. Enable at your discretion.
=====================================================================================================*/
/*
set @sql = 'drop login [' + @LoginName + ']'
exec sp_executesql @sql
*/
