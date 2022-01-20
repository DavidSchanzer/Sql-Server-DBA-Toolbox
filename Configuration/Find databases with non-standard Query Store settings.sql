-- Find databases with non-standard Query Store settings
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists, for all applicable versions, the databases that don't have Query Store enabled in READ_WRITE mode, with the AUTO capture mode,
-- Wait Stats Capture Mode enabled, the Stale Query Threshold set to 60 days, and the Max Storage Size set to 1000 MB.

DECLARE @ver TINYINT
    = CAST(LEFT(CONVERT(VARCHAR(128), SERVERPROPERTY('productversion')), CHARINDEX(
                                                                                      '.',
                                                                                      CONVERT(
                                                                                                 VARCHAR(128),
                                                                                                 SERVERPROPERTY('productversion')
                                                                                             )
                                                                                  ) - 1) AS TINYINT);

CREATE TABLE #DBQS
(
    db_name NVARCHAR(128) NOT NULL,
    is_primary_replica BIT NULL,
    actual_state SMALLINT NOT NULL,
    query_capture_mode SMALLINT NOT NULL,
    stale_query_threshold_days SMALLINT NOT NULL,
    max_storage_size_mb INT NOT NULL,
    wait_stats_capture_mode SMALLINT NULL
);

IF @ver >= 13 -- SQL 2016 or later
BEGIN
    IF @ver = 13 -- SQL 2016
    BEGIN
        EXEC sp_ineachdb 'INSERT INTO #DBQS ( db_name, is_primary_replica, actual_state, query_capture_mode, stale_query_threshold_days, max_storage_size_mb ) SELECT db_name(), sys.fn_hadr_is_primary_replica ( ''?'' ), actual_state, query_capture_mode, stale_query_threshold_days, max_storage_size_mb FROM sys.database_query_store_options';
    END;
    ELSE -- SQL 2017 or later
    BEGIN
        EXEC sp_ineachdb 'INSERT INTO #DBQS ( db_name, is_primary_replica, actual_state, query_capture_mode, stale_query_threshold_days, max_storage_size_mb, wait_stats_capture_mode ) SELECT db_name(), sys.fn_hadr_is_primary_replica ( ''?'' ), actual_state, query_capture_mode, stale_query_threshold_days, max_storage_size_mb, wait_stats_capture_mode FROM sys.database_query_store_options';
    END;
END;

SELECT D.db_name,
       D.is_primary_replica,
       D.actual_state,
       D.query_capture_mode,
       D.stale_query_threshold_days,
       D.max_storage_size_mb,
       D.wait_stats_capture_mode
FROM #DBQS AS D
    INNER JOIN sys.databases AS DB
        ON DB.name = D.db_name
WHERE (
          D.is_primary_replica = 1
          OR D.is_primary_replica IS NULL
      )
      AND
      (
          D.actual_state != 2 -- Not in READ_WRITE mode
          OR D.query_capture_mode != 2 -- Not in AUTO query capture mode
          OR
          (
              D.wait_stats_capture_mode IS NOT NULL
              AND D.wait_stats_capture_mode != 1
          ) -- Wait Stats Capture Mode is not turned on
          OR D.stale_query_threshold_days != 60 -- Not set to 60 days
          OR D.max_storage_size_mb != 1000
      ) -- Query Store max size not set to 1000 MB
      AND D.db_name NOT IN ( 'msdb', 'distribution' ) -- Not one of these database names
      AND DB.is_read_only != 1; -- Not a read-only database

DROP TABLE #DBQS;
GO
