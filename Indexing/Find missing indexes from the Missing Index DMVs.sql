-- Find missing indexes from the Missing Index DMVs
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script checks the dm_db_missing_index_... DMVs for missing indexes tracked by SQL Server, which will be cleared on instance restart.
-- The combined calculated Impact must be 1 million or above, and user_seeks + user_scans must be 1000 or above.

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
    avg_total_user_cost FLOAT NULL,
    avg_user_impact FLOAT NULL,
    user_seeks BIGINT NULL,
    user_scans BIGINT NULL,
    [Table] NVARCHAR(4000) NULL,
    CreateIndexStatement NVARCHAR(4000) NULL,
    equality_columns NVARCHAR(4000) NULL,
    inequality_columns NVARCHAR(4000) NULL,
    included_columns NVARCHAR(4000) NULL,
    last_user_seek DATETIME NULL,
    last_user_scan DATETIME NULL
);

INSERT INTO #Temp
(
    [Database],
    Impact,
    avg_total_user_cost,
    avg_user_impact,
    user_seeks,
    user_scans,
    [Table],
    CreateIndexStatement,
    equality_columns,
    inequality_columns,
    included_columns,
    last_user_seek,
    last_user_scan
)
EXEC dbo.sp_ineachdb @command = 'SELECT db_name(db_id()) as [Database],
	[Impact] = (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans),  
	avg_total_user_cost, avg_user_impact, user_seeks, user_scans,
	[Table] = [statement],
	[CreateIndexStatement] = ''CREATE NONCLUSTERED INDEX [IX_'' 
		+ sys.objects.name COLLATE DATABASE_DEFAULT 
		+ ''_'' 
		+ REPLACE(REPLACE(REPLACE(ISNULL(mid.equality_columns,'''')+ CASE WHEN mid.inequality_columns IS NOT NULL THEN ''_'' ELSE '''' END + ISNULL(mid.inequality_columns,''''), ''['', ''''), '']'',''''), '', '',''_'')
		+ CASE WHEN mid.included_columns IS NOT NULL THEN ''_includes'' ELSE '''' END
		+ ''] ON ''
		+ [statement] 
		+ '' ( '' + IsNull(mid.equality_columns, '''') 
		+ CASE WHEN mid.inequality_columns IS NULL THEN '''' ELSE 
			CASE WHEN mid.equality_columns IS NULL THEN '''' ELSE '','' END 
		+ mid.inequality_columns END + '' ) '' 
		+ CASE WHEN mid.included_columns IS NULL THEN '''' ELSE ''INCLUDE ('' + mid.included_columns + '')'' END 
		+ '';'', 
	mid.equality_columns, mid.inequality_columns, mid.included_columns, migs.last_user_seek, migs.last_user_scan
FROM sys.dm_db_missing_index_group_stats AS migs 
	INNER JOIN sys.dm_db_missing_index_groups AS mig ON migs.group_handle = mig.index_group_handle 
	INNER JOIN sys.dm_db_missing_index_details AS mid ON mig.index_handle = mid.index_handle 
	INNER JOIN sys.objects WITH (nolock) ON mid.OBJECT_ID = sys.objects.OBJECT_ID AND mid.database_id = db_id()
WHERE /*(migs.group_handle IN (SELECT TOP (500) group_handle FROM sys.dm_db_missing_index_group_stats WITH (NOLOCK) ORDER BY (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) DESC))  
	AND*/ ( OBJECTPROPERTY(sys.objects.OBJECT_ID, ''isusertable'') = 1 OR OBJECTPROPERTY(sys.objects.OBJECT_ID, ''isview'') = 1 )
	AND (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) > 1000000
	AND user_seeks + user_scans > 1000
	AND db_id() > 4
ORDER BY [Impact] DESC , [CreateIndexStatement] DESC';

SELECT [Database],
       Impact,
       avg_total_user_cost,
       avg_user_impact,
       user_seeks,
       user_scans,
       [Table],
       CreateIndexStatement,
       equality_columns,
       inequality_columns,
       included_columns,
       last_user_seek,
       last_user_scan
FROM #Temp;

DROP TABLE #Temp;
