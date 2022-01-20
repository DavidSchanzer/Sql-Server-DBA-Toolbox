-- Set all databases to maximum compatibility level
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script sets the Compatibility Level for all databases to the maximum value (ie. to match the instance version)

DECLARE @MaximumDBCompatLevel TINYINT;

DECLARE @TrimmedVersion VARCHAR(20) = LTRIM(RTRIM(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(20))));
DECLARE @IsValidLooking BIT = CASE
                                  WHEN LEN(REPLACE(@TrimmedVersion, '.', '')) = (LEN(@TrimmedVersion) - 3) THEN
                                      CAST(1 AS BIT)
                                  ELSE
                                      CAST(0 AS BIT)
                              END;
DECLARE @FirstPeriod INT;
DECLARE @MajorVersionString VARCHAR(20);
DECLARE @MajorVersion INT;
DECLARE @DatabaseName sysname;

IF @IsValidLooking <> 0
BEGIN
    SET @FirstPeriod = CHARINDEX('.', @TrimmedVersion, 1);
    SET @MajorVersionString = SUBSTRING(@TrimmedVersion, 1, @FirstPeriod - 1);

    SET @MajorVersion = CASE
                            WHEN ISNUMERIC(@MajorVersionString) = 1 THEN
                                CAST(@MajorVersionString AS INT)
                        END;

    SET @MaximumDBCompatLevel = @MajorVersion * 10;

    DECLARE @DatabasesToUpdate TABLE
    (
        DatabasesToUpdateID INT IDENTITY(1, 1) PRIMARY KEY,
        DatabaseName sysname NULL
    );

    INSERT @DatabasesToUpdate
    (
        DatabaseName
    )
    SELECT name
    FROM sys.databases
    WHERE compatibility_level <> @MaximumDBCompatLevel;

    DECLARE @Counter INT = 1;
    DECLARE @SQL NVARCHAR(MAX) = N'';

    WHILE @Counter <= (SELECT MAX(DatabasesToUpdateID)FROM @DatabasesToUpdate)
    BEGIN
        SELECT @DatabaseName = dtu.DatabaseName
        FROM @DatabasesToUpdate AS dtu
        WHERE dtu.DatabasesToUpdateID = @Counter;

        SET @SQL
            = N'ALTER DATABASE ' + QUOTENAME(@DatabaseName) + N' SET COMPATIBILITY_LEVEL = '
              + CAST(@MaximumDBCompatLevel AS NVARCHAR(10)) + N';';

        EXEC (@SQL);
        SET @Counter += 1;
    END;
END;
