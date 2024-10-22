-- Find missing indexes from the Missing Index DMVs
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script checks the dm_db_missing_index_... DMVs for missing indexes tracked by SQL Server, which will be cleared on instance restart.
-- The combined calculated Impact must be 1 million or above, and UserSeeks + UserScans must be 1000 or above.

/* ------------------------------------------------------------------
-- Title:	FindMissingIndices
-- Author:	Brent Ozar
-- Date:	2009-04-01 
-- Modified By: Clayton Kramer <CKRAMER.KRAMER gmail.com @>
-- Description: This query returns indices that SQL Server 2005 
-- (and higher) thinks are missing since the last restart. The 
-- "Impact" column is relative to the time of last restart and how 
-- bad SQL Server needs the index. 10 million+ is high.
-- Changes: Updated to expose full table name. This makes it easier
-- to identify which database needs an index. Modified the 
-- CreateIndexStatement to use the full table path and include the
-- equality/inequality columns for easier identification.
------------------------------------------------------------------*/
IF OBJECT_ID('TempDB..#Temp', 'U') > 0
    DROP TABLE #Temp;

CREATE TABLE #Temp
(
    [Database] NVARCHAR(128) NULL,
    Impact FLOAT NULL,
    AvgTotalUserCost FLOAT NULL,
    AvgUserImpact FLOAT NULL,
    UserSeeks BIGINT NULL,
    UserScans BIGINT NULL,
    [Table] NVARCHAR(4000) NULL,
    CreateIndexStatement NVARCHAR(4000) NULL,
    EqualityColumns NVARCHAR(4000) NULL,
    InequalityColumns NVARCHAR(4000) NULL,
    IncludedColumns NVARCHAR(4000) NULL,
    LastUserSeek DATETIME NULL,
    LastUserScan DATETIME NULL,
    InstanceStartTime DATETIME NULL
);

INSERT INTO #Temp
(
    [Database],
    Impact,
    AvgTotalUserCost,
    AvgUserImpact,
    UserSeeks,
    UserScans,
    [Table],
    CreateIndexStatement,
    EqualityColumns,
    InequalityColumns,
    IncludedColumns,
    LastUserSeek,
    LastUserScan,
    InstanceStartTime
)
EXEC dbo.sp_ineachdb @command = 'SELECT DB_NAME(DB_ID()) AS [Database],
       [Impact] = (migs.avg_total_user_cost * migs.avg_user_impact) * (migs.user_seeks + migs.user_scans),
       migs.avg_total_user_cost AS AvgTotalUserCost,
       migs.avg_user_impact AS AvgUserImpact,
       migs.user_seeks AS UserSeeks,
       migs.user_scans AS UserScans,
       [Table] = mid.statement,
       [CreateIndexStatement] = ''CREATE NONCLUSTERED INDEX [IX_'' + name COLLATE DATABASE_DEFAULT + ''_''
                                + REPLACE(
                                             REPLACE(
                                                        REPLACE(
                                                                   ISNULL(mid.equality_columns, '''')
                                                                   + CASE
                                                                         WHEN mid.inequality_columns IS NOT NULL THEN
                                                                             ''_''
                                                                         ELSE
                                                                             ''''
                                                                     END + IsNull(mid.inequality_columns, ''''),
                                                                   ''['',
                                                                   ''''
                                                               ),
                                                        '']'',
                                                        ''''
                                                    ),
                                             '', '',
                                             ''_''
                                         ) + CASE
                                                 WHEN mid.included_columns IS NOT NULL THEN
                                                     ''_includes''
                                                 ELSE
                                                     ''''
                                             END + ''] ON '' + mid.statement + '' ( '' + IsNull(mid.equality_columns, '''')
                                + CASE
                                      WHEN mid.inequality_columns IS NULL THEN
                                          ''''
                                      ELSE
                                          CASE
                                              WHEN mid.equality_columns IS NULL THEN
                                                  ''''
                                              ELSE
                                                  '',''
                                          END + mid.inequality_columns
                                  END + '' ) '' + CASE
                                                    WHEN mid.included_columns IS NULL THEN
                                                        ''''
                                                    ELSE
                                                        ''INCLUDE ('' + mid.included_columns + '')''
                                                END + '';'',
       mid.equality_columns AS EqualityColumns,
       mid.inequality_columns AS InequalityColumns,
       mid.included_columns AS IncludedColumns,
       migs.last_user_seek AS LastUserSeek,
       migs.last_user_scan AS LastUserScan,
       (
           SELECT TOP 1 sqlserver_start_time FROM sys.dm_os_sys_info
       ) AS InstanceStartTime
FROM sys.dm_db_missing_index_group_stats AS migs
    INNER JOIN sys.dm_db_missing_index_groups AS mig
        ON migs.group_handle = mig.index_group_handle
    INNER JOIN sys.dm_db_missing_index_details AS mid
        ON mig.index_handle = mid.index_handle
    INNER JOIN sys.objects WITH (NOLOCK)
        ON mid.object_id = sys.objects.object_id
           AND mid.database_id = DB_ID()
WHERE /*(migs.group_handle IN (SELECT TOP (500) group_handle FROM sys.dm_db_missing_index_group_stats WITH (NOLOCK) ORDER BY (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) DESC))  
    AND*/
    (
        OBJECTPROPERTY(sys.objects.object_id, ''isusertable'') = 1
        OR OBJECTPROPERTY(sys.objects.object_id, ''isview'') = 1
    )
    AND (migs.avg_total_user_cost * migs.avg_user_impact) * (migs.user_seeks + migs.user_scans) > 1000000
    AND user_seeks + user_scans > 1000
    AND DB_ID() > 4
ORDER BY [Impact] DESC,
         [CreateIndexStatement] DESC;';

SELECT [Database],
       Impact,
       AvgTotalUserCost,
       AvgUserImpact,
       UserSeeks,
       UserScans,
       [Table],
       CreateIndexStatement,
       EqualityColumns,
       InequalityColumns,
       IncludedColumns,
       LastUserSeek,
       LastUserScan,
       InstanceStartTime
FROM #Temp;

DROP TABLE #Temp;
