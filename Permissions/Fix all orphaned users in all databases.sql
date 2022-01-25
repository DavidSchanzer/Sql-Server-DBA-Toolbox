-- Fix all orphaned users in all databases
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script executes sp_change_users_login 'Report' on each user database, then for each orphaned user found, it calls sp_change_users_login
-- again, this time with 'Update_One' to re-link the user with the login.

EXEC dbo.sp_ineachdb @command = '
CREATE TABLE #OrphanedUsers
(
    row_num INT IDENTITY(1, 1),
    username VARCHAR(1000),
    id VARCHAR(1000)
);

INSERT INTO #OrphanedUsers
(
    username,
    id
)
EXEC sys.sp_change_users_login ''Report'';

DECLARE @rowCount INT =
        (
            SELECT COUNT(1) FROM #OrphanedUsers
        );

DECLARE @i INT = 1;
DECLARE @tempUsername VARCHAR(1000);

WHILE (@i <= @rowCount)
BEGIN
    SELECT @tempUsername = username
    FROM #OrphanedUsers
    WHERE row_num = @i;

	EXEC sys.sp_change_users_login @Action = ''Update_One'', @UserNamePattern = @tempUsername, @LoginName = @tempUsername;

    SET @i = @i + 1;
END;

DROP TABLE #OrphanedUsers;
',
                      @user_only = 1;
