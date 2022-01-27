-- Find Windows logins that are no longer in AD
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script 

DECLARE @user sysname;

DECLARE recscan CURSOR LOCAL FAST_FORWARD FOR
SELECT name
FROM sys.server_principals
WHERE type LIKE '[UG]'
      AND name LIKE '<InsertYourDomainNameHere>\%';

OPEN recscan;
FETCH NEXT FROM recscan
INTO @user;

CREATE TABLE #Temp
(
    AccountName SYSNAME NOT NULL,
    Type VARCHAR(8) NOT NULL,
    Privilege VARCHAR(8) NOT NULL,
    MappedLoginName SYSNAME NOT NULL,
    PermissionPath SYSNAME NULL
);

WHILE @@fetch_status = 0
BEGIN
    BEGIN TRY
        INSERT INTO #Temp
        (
            AccountName,
            Type,
            Privilege,
            MappedLoginName,
            PermissionPath
        )
        EXEC master.sys.xp_logininfo @acctname = @user;
    END TRY
    BEGIN CATCH
        --Error on xproc because login doesn't exist
        SELECT 'DROP LOGIN ' + CONVERT(VARCHAR, @user);
    END CATCH;

    TRUNCATE TABLE #Temp;

    FETCH NEXT FROM recscan
    INTO @user;
END;

DROP TABLE #Temp;

CLOSE recscan;
DEALLOCATE recscan;
