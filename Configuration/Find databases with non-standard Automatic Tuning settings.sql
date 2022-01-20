-- Find databases with non-standard Automatic Tuning settings
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists, for all Enterprise Edition instances of SQL Server 2017 or later, the databases that don't have Automatic Tuning enabled

DECLARE @ver TINYINT
    = CAST(LEFT(CONVERT(VARCHAR(128), SERVERPROPERTY('productversion')), CHARINDEX(
                                                                                      '.',
                                                                                      CONVERT(
                                                                                                 VARCHAR(128),
                                                                                                 SERVERPROPERTY('productversion')
                                                                                             )
                                                                                  ) - 1) AS TINYINT),
        @edition TINYINT = CAST(SERVERPROPERTY('EngineEdition') AS TINYINT);

CREATE TABLE #DBAT
(
    db_name NVARCHAR(128) NOT NULL,
    is_primary_replica BIT NULL,
    actual_state SMALLINT NOT NULL
);

IF @ver >= 14
   AND @edition = 3 -- SQL Enterprise 2017 or later
BEGIN
    EXEC sp_ineachdb 'INSERT INTO #DBAT ( db_name, is_primary_replica, actual_state ) SELECT db_name(), sys.fn_hadr_is_primary_replica ( ''?'' ), actual_state FROM sys.database_automatic_tuning_options ';
END;

SELECT *
FROM #DBAT
WHERE (
          is_primary_replica = 1
          OR is_primary_replica IS NULL
      )
      AND actual_state <> 1 -- Not ON
      AND db_name NOT IN ( 'model', 'msdb' );

DROP TABLE #DBAT;
GO
