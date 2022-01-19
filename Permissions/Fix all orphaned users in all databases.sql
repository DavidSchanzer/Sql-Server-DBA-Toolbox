EXEC dbo.sp_foreachdb '
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
