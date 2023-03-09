-- Drop All Redundant Indexes In Every Database All At Once
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- From https://www.madeiradata.com/post/every-redundant-index-in-every-database-all-at-once
/*
Detailed Redundant Indexes Check and Remediation for All Databases
==================================================================
Author: Eitan Blumin
Date Created: 2020-07-16
Last Updated: 2023-01-01

By default, this script outputs two different resultsets.

The first one is a "detailed" resultset showing all redundant indexes and the indexes that "contain" them. It has a lot of useful details, but could possibly contain duplicate information 
(if the same index is "contained" in more than one index).

The second resultset is a "summary" resultset showing only the redundant indexes, and each redundant index is shown only once. There is no duplicate information here, but some details are missing 
(which you can find in the first resultset). You can use this second resultset as your single source of truth for which redundant indexes should be dropped/disabled.

Take note of the columns "*_index_seeks", "*_index_scans", and "*_index_updates" to get an idea about the "popularity" of the redundant indexes compared to their containing counterparts.

Also, take note of the "redundant_index_pages" column as an indication of the current size of the index. Divide this number by 128 to get an equivalent size in MB 
(a division of the number of pages by 128 is the equivalent of multiplying by 8 to get the value in KB and then dividing by 1024 to get the value in MB). 
NOTE: In the second (summary) resultset, redundant_index_mb is already calculated for you.

The "DisableCmd" column can be used to quickly get the corresponding ALTER INDEX .. DISABLE commands to disable the redundant indexes. You can also use the "DisableIfActiveCmd" column 
for an "idempotent" alternative (only disables the index if it exists and is enabled).

The "DropCmd" column can be used to quickly get the corresponding DROP INDEX commands to drop the redundant indexes. It is also idempotent (only drops the index if it exists).

Optionally, changing the variable at the top @CompareIncludeColumnsToo to 0, will somewhat change the behavior of the script:

Instead of comparing the redundancy of indexes based on both key columns and include columns, the script will only compare the key columns. This will likely return even more "redundant" indexes, 
but you must beware as they are not necessarily "fully" redundant.

An additional 3rd resultset will be returned in the output precisely for this purpose.

It contains a column called "ExpandIndexCommand" which would have CREATE INDEX commands for "Fully Covering Indexes" that should be created to accommodate all redundant indexes based on the key columns. 
In other words, it takes the index with the most key columns, and adds to it all the include columns from all of its redundant counterparts.

This 3rd resultset also contains two additional columns "DisableRedundantIndexes" and "DropRedundantIndexes" that can be used to easily get rid of all the redundant indexes that would be replaced by 
the new covering index.
*/

DECLARE @FilterByDatabase		sysname	= NULL	/* optionally specify a specific database name to check, or leave NULL to check all accessible and writeable databases */
DECLARE @MinimumRowsInTable		int	= 100000	/* filter tables by minimum number of rows */
DECLARE @CompareIncludeColumnsToo	bit	= 1		/* set to 0 to only compare by key columns, but this will also generate recommendations for new include column sets that encompass all redundant indexes per each containing index */

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results;
CREATE TABLE #Results
(
[database_name]	sysname NULL,
[schema_name]	sysname NULL,
table_name	sysname NULL,
total_columns_count int NULL,
redundant_index_name	sysname NULL,
redundant_key_columns	nvarchar(MAX) NULL,
redundant_include_columns	nvarchar(MAX) NULL,
redundant_index_filter	nvarchar(MAX) NULL,
redundant_index_seeks	bigint NULL,
redundant_index_last_user_seek	datetime NULL,
redundant_index_scans	bigint NULL,
redundant_index_updates	bigint NULL,
redundant_index_last_user_update datetime NULL,
redundant_index_pages	bigint NULL,
containing_index_name	sysname NULL,
containing_key_columns	nvarchar(MAX) NULL,
containing_include_columns	nvarchar(MAX) NULL,
containing_index_filter	nvarchar(MAX) NULL,
containing_index_seeks	bigint NULL,
containing_index_last_user_seek	datetime NULL,
containing_index_scans	bigint NULL,
containing_index_updates bigint NULL,
containing_index_last_user_update datetime NULL,
containing_index_pages	bigint NULL,
containing_index_clustered bit NULL,
containing_index_unique bit NULL
);

DECLARE @CMD NVARCHAR(MAX);
SET @CMD = N'IF OBJECT_ID(''tempdb..#FindOnThisDB'') IS NOT NULL DROP TABLE #FindOnThisDB;
;WITH Indexes AS
(
select
sets.schema_id,
sets.table_o_id,
sets.key_column_list,
sets.include_column_list,
sets.is_unique,
sets.index_number,
sets.filter_definition
from
(
SELECT
SCHEMA_DATA.schema_id,
TABLE_DATA.object_id as table_o_id,
INDEX_DATA.object_id as index_o_id,
INDEX_DATA.index_id as index_number,
INDEX_DATA.is_unique,
INDEX_DATA.name,
(
SELECT QUOTENAME(cast(keyCol.column_id as varchar(max)) + CASE WHEN keyCol.is_descending_key = 1 THEN ''d'' ELSE ''a'' END, ''{'')
FROM sys.tables AS T
INNER JOIN sys.indexes idx ON T.object_id = idx.object_id
INNER JOIN sys.index_columns keyCol ON idx.object_id = keyCol.object_id AND idx.index_id = keyCol.index_id
WHERE INDEX_DATA.object_id = idx.object_id
AND INDEX_DATA.index_id = idx.index_id
AND keyCol.is_included_column = 0
ORDER BY keyCol.key_ordinal
FOR XML PATH('''')
) AS key_column_list ,
(
SELECT QUOTENAME(cast(keyColINC.column_id as varchar(max)), ''{'')
FROM sys.tables AS T
INNER JOIN sys.indexes idxINC ON T.object_id = idxINC.object_id
INNER JOIN sys.index_columns keyColINC ON idxINC.object_id = keyColINC.object_id AND idxINC.index_id = keyColINC.index_id
WHERE
INDEX_DATA.object_id = idxINC.object_id
AND INDEX_DATA.index_id = idxINC.index_id
AND keyColINC.is_included_column = 1
ORDER BY keyColINC.column_id
FOR XML PATH('''')
) AS include_column_list ,
INDEX_DATA.filter_definition
FROM sys.indexes INDEX_DATA
INNER JOIN sys.tables TABLE_DATA ON TABLE_DATA.object_id = INDEX_DATA.object_id
INNER JOIN sys.schemas SCHEMA_DATA ON SCHEMA_DATA.schema_id = TABLE_DATA.schema_id

WHERE TABLE_DATA.is_ms_shipped = 0
and INDEX_DATA.is_disabled = 0
AND INDEX_DATA.data_space_id > 0
) AS sets
LEFT JOIN sys.partitions p
ON sets.table_o_id = p.OBJECT_ID AND sets.index_number = p.index_id
where sets.key_column_list is not null
GROUP BY sets.schema_id, sets.table_o_id, sets.index_number, sets.is_unique, sets.key_column_list, sets.include_column_list, sets.filter_definition
HAVING sum(p.rows) >= ' + CAST(@MinimumRowsInTable AS NVARCHAR(MAX)) + N'
)
SELECT
DISTINCT
DUPE1.schema_id as schema_id,
DUPE1.table_o_id as table_object_id,
DUPE1.index_number as redundant_index_id ,
DUPE2.index_number as containing_index_id ,
DUPE1.filter_definition as redundant_index_filter,
DUPE2.filter_definition as containing_index_filter,
DUPE1.key_column_list, DUPE1.include_column_list
into #FindOnThisDB
FROM Indexes DUPE1
INNER JOIN Indexes DUPE2
ON
DUPE1.schema_id = DUPE2.schema_id
AND DUPE1.table_o_id = DUPE2.table_o_id
AND DUPE1.index_number <> 1 -- do not consider clustered indexes as redundant
AND DUPE1.is_unique = 0 -- do not consider unique indexes as redundant
AND (
DUPE1.key_column_list = LEFT(DUPE2.key_column_list, LEN(DUPE1.key_column_list)
)' + CASE WHEN @CompareIncludeColumnsToo = 1 THEN N' and
(DUPE1.include_column_list is null OR DUPE1.include_column_list = LEFT(DUPE2.include_column_list, LEN(DUPE1.include_column_list)))'
 ELSE N'' END + N'
)
AND DUPE1.index_number <> DUPE2.index_number
AND ISNULL(DUPE1.filter_definition, '''') = ISNULL(DUPE2.filter_definition, '''')
;

SELECT
[database_name] = DB_NAME(),
[schema_name] = sch.name,
table_name = tb.name,
total_columns_count = (SELECT COUNT(*) FROM sys.columns AS allc WHERE allc.object_id = tb.object_id AND allc.is_computed = 0),
ind1.name as redundant_index_name,
redundant_key_columns = STUFF
((
SELECT '', '' + QUOTENAME(col.name) + CASE WHEN keyCol.is_descending_key = 1 THEN '' DESC'' ELSE '' ASC'' END
FROM sys.index_columns keyCol
inner join sys.columns col on keyCol.object_id = col.object_id AND keyCol.column_id = col.column_id
WHERE ind1.object_id = keyCol.object_id
AND ind1.index_id = keyCol.index_id
AND keyCol.is_included_column = 0
ORDER BY keyCol.key_ordinal
FOR XML PATH('''')), 1, 2, ''''),
redundant_include_columns = STUFF
((
SELECT '', '' + QUOTENAME(col.name)
FROM sys.index_columns keyCol
inner join sys.columns col on keyCol.object_id = col.object_id AND keyCol.column_id = col.column_id
WHERE ind1.object_id = keyCol.object_id
AND ind1.index_id = keyCol.index_id
AND keyCol.is_included_column = 1
ORDER BY keyCol.key_ordinal
FOR XML PATH('''')), 1, 2, ''''),
tbl.redundant_index_filter,
redundant_index_seeks = us1.user_seeks,
redundant_index_last_user_seek = us1.last_user_seek,
redundant_index_scans = us1.user_scans,
redundant_index_updates = us1.user_updates,
redundant_index_last_user_update = us1.last_user_update,
redundant_index_pages = (SELECT SUM(reserved_page_count) FROM sys.dm_db_partition_stats AS ps WHERE ind1.index_id = ps.index_id AND ps.OBJECT_ID = ind1.OBJECT_ID),
containing_index_name = ind2.name,
containing_key_columns = STUFF
((
SELECT '', '' + QUOTENAME(col.name) + CASE WHEN keyCol.is_descending_key = 1 THEN '' DESC'' ELSE '' ASC'' END
FROM sys.index_columns keyCol
inner join sys.columns col on keyCol.object_id = col.object_id AND keyCol.column_id = col.column_id
WHERE ind2.object_id = keyCol.object_id
AND ind2.index_id = keyCol.index_id
AND keyCol.is_included_column = 0
ORDER BY keyCol.key_ordinal
FOR XML PATH('''')), 1, 2, ''''),
containing_include_columns = STUFF
((
SELECT '', '' + QUOTENAME(col.name)
FROM sys.index_columns keyCol
inner join sys.columns col on keyCol.object_id = col.object_id AND keyCol.column_id = col.column_id
WHERE ind2.object_id = keyCol.object_id
AND ind2.index_id = keyCol.index_id
AND keyCol.is_included_column = 1
ORDER BY keyCol.key_ordinal
FOR XML PATH('''')), 1, 2, ''''),
tbl.containing_index_filter,
containing_index_seeks = us2.user_seeks,
containing_index_last_user_seek = us2.last_user_seek,
containing_index_scans = us2.user_scans,
containing_index_updates = us2.user_updates,
containing_index_last_user_update = us2.last_user_update,
containing_index_pages = (SELECT SUM(reserved_page_count) FROM sys.dm_db_partition_stats AS ps WHERE ind2.index_id = ps.index_id AND ps.OBJECT_ID = ind2.OBJECT_ID),
containing_index_clustered = CASE WHEN ind2.index_id = 1 THEN 1 ELSE 0 END,
containing_index_unique = ind2.is_unique
from #FindOnThisDB AS tbl
INNER JOIN sys.tables tb
ON tb.object_id = tbl.table_object_id
INNER JOIN sys.schemas sch
ON sch.schema_id = tbl.schema_id
INNER JOIN sys.indexes ind1
ON ind1.object_id = tbl.table_object_id and ind1.index_id = tbl.redundant_index_id
INNER JOIN sys.indexes ind2
ON ind2.object_id = tbl.table_object_id and ind2.index_id = tbl.containing_index_id
LEFT JOIN sys.dm_db_index_usage_stats AS us1 ON us1.database_id = DB_ID() AND us1.object_id = ind1.object_id AND us1.index_id = ind1.index_id
LEFT JOIN sys.dm_db_index_usage_stats AS us2 ON us2.database_id = DB_ID() AND us2.object_id = ind2.object_id AND us2.index_id = ind2.index_id
WHERE ind1.index_id > 0 AND ind2.index_id > 0'

DECLARE @dbname sysname, @spExecuteSql NVARCHAR(1000), @RCount int;

DECLARE DBs CURSOR
LOCAL FAST_FORWARD
FOR 
SELECT [name]
FROM sys.databases
WHERE
(
	    @FilterByDatabase IS NULL
	AND database_id > 4
	AND HAS_DBACCESS([name]) = 1
	AND DATABASEPROPERTYEX([name], 'Updateability') = 'READ_WRITE'
)
OR @FilterByDatabase = [name];

OPEN DBs;

WHILE 1=1
BEGIN
	FETCH NEXT FROM DBs INTO @dbname;
	IF @@FETCH_STATUS <> 0 BREAK;

	SET @spExecuteSql = QUOTENAME(@dbname) + N'..sp_executesql'

	SET @RCount = NULL;

	INSERT INTO #Results
	EXEC @spExecuteSql @CMD WITH RECOMPILE;

	SET @RCount = @@ROWCOUNT;
	IF @RCount > 0 RAISERROR(N'Found %d redundant index(es) in database "%s"',0,1,@RCount,@dbname) WITH NOWAIT;
END
CLOSE DBs;
DEALLOCATE DBs;

SELECT *,
DisableIfActiveCmd = CASE WHEN DropPriority > 1 THEN N'-- do not drop' ELSE N'USE ' + QUOTENAME([database_name]) + N'; IF INDEXPROPERTY(OBJECT_ID(''' + QUOTENAME([schema_name]) + N'.' + QUOTENAME(table_name) + N'''), ''' + redundant_index_name + N''', ''IsDisabled'') = 0 ALTER INDEX ' + QUOTENAME(redundant_index_name) + N' ON ' + QUOTENAME([schema_name]) + N'.' + QUOTENAME(table_name) + N' DISABLE;' END,
DropCmd = CASE WHEN DropPriority > 1 THEN N'-- do not drop' ELSE N'USE ' + QUOTENAME([database_name]) + N'; IF INDEXPROPERTY(OBJECT_ID(''' + QUOTENAME([schema_name]) + N'.' + QUOTENAME(table_name) + N'''), ''' + redundant_index_name + N''', ''IndexID'') IS NOT NULL DROP INDEX ' + QUOTENAME(redundant_index_name) + N' ON ' + QUOTENAME([schema_name]) + N'.' + QUOTENAME(table_name) + N';' END
FROM
(
SELECT *,
IsIdentical = CASE WHEN [redundant_key_columns] = containing_key_columns AND ISNULL(redundant_include_columns,'') = ISNULL(containing_include_columns,'') THEN 1 ELSE 0 END,
containing_indexes_count = COUNT(*) OVER (PARTITION BY [database_name], [schema_name], table_name, redundant_index_name),
DropPriority = ROW_NUMBER() OVER (PARTITION BY [database_name], [schema_name], table_name, redundant_key_columns, redundant_include_columns ORDER BY redundant_index_pages DESC, redundant_index_seeks ASC, redundant_index_scans ASC)
FROM #Results
) AS q
ORDER BY [database_name], [schema_name], table_name, redundant_index_name
OPTION(RECOMPILE);

SELECT [database_name], [schema_name], table_name, redundant_index_name
, redundant_index_seeks
, redundant_index_last_user_seek = MAX(redundant_index_last_user_seek)
, redundant_index_mb = redundant_index_pages / 128.0
, redundant_index_updates
, redundant_index_last_user_update = MAX(redundant_index_last_user_update)
, containing_indexes_count
, DisableIfActiveCmd, DropCmd
FROM (
SELECT *,
IsIdentical = CASE WHEN [redundant_key_columns] = containing_key_columns AND ISNULL(redundant_include_columns,'') = ISNULL(containing_include_columns,'') THEN 1 ELSE 0 END,
containing_indexes_count = COUNT(*) OVER (PARTITION BY [database_name], [schema_name], table_name, redundant_index_name),
DropPriority = ROW_NUMBER() OVER (PARTITION BY [database_name], [schema_name], table_name, redundant_key_columns, redundant_include_columns ORDER BY redundant_index_pages DESC, redundant_index_seeks ASC, redundant_index_scans ASC),
DisableIfActiveCmd = N'USE ' + QUOTENAME([database_name]) + N'; IF INDEXPROPERTY(OBJECT_ID(''' + QUOTENAME([schema_name]) + N'.' + QUOTENAME(table_name) + N'''), ''' + redundant_index_name + N''', ''IsDisabled'') = 0 ALTER INDEX ' + QUOTENAME(redundant_index_name) + N' ON ' + QUOTENAME([schema_name]) + N'.' + QUOTENAME(table_name) + N' DISABLE;',
DropCmd = N'USE ' + QUOTENAME([database_name]) + N'; IF INDEXPROPERTY(OBJECT_ID(''' + QUOTENAME([schema_name]) + N'.' + QUOTENAME(table_name) + N'''), ''' + redundant_index_name + N''', ''IndexID'') IS NOT NULL DROP INDEX ' + QUOTENAME(redundant_index_name) + N' ON ' + QUOTENAME([schema_name]) + N'.' + QUOTENAME(table_name) + N';'
FROM #Results
) AS q
WHERE DropPriority = 1
GROUP BY [database_name], [schema_name], table_name, redundant_index_name
, redundant_index_seeks
, redundant_index_pages
, redundant_index_updates
, containing_indexes_count
, DisableIfActiveCmd, DropCmd
OPTION(RECOMPILE);

IF @CompareIncludeColumnsToo = 0
BEGIN

SELECT [database_name], [schema_name], table_name, containing_index_name, containing_key_columns, containing_include_columns
, containing_index_filter, containing_index_clustered, containing_index_unique
, total_columns_count
, this_index_columns_count = 
(SELECT COUNT(*) FROM string_split(incNew.NewIncludeColumns,','))
+
(SELECT COUNT(*) FROM string_split(containing_key_columns, ','))
, incNew.NewIncludeColumns
, ExpandIndexCommand = CASE WHEN ISNULL(containing_include_columns, N'') <> ISNULL(incNew.NewIncludeColumns, N'') THEN
	N'USE ' + QUOTENAME([database_name]) + N'; CREATE'
	+ CASE WHEN containing_index_unique = 1 THEN N' UNIQUE' ELSE N'' END
	+ N' NONCLUSTERED INDEX ' + QUOTENAME(containing_index_name) + N' ON ' + QUOTENAME([schema_name]) + N'.' + QUOTENAME(table_name)
	+ N' (' + containing_key_columns + N')' + ISNULL(N' INCLUDE(' + incNew.NewIncludeColumns + N')', N'') + ISNULL(N' WHERE ' + containing_index_filter, N'')
	+ N' WITH (DROP_EXISTING = ON); '
	ELSE N'/* ' + QUOTENAME([database_name]) + N': leave index ' + QUOTENAME(containing_index_name) + N' ON ' + QUOTENAME([schema_name]) + N'.' + QUOTENAME(table_name) + N' unchanged */' END
, DisableRedundantIndexes = 
STUFF((
SELECT 
N'; USE ' + QUOTENAME([database_name]) + N'; IF INDEXPROPERTY(OBJECT_ID(''' + QUOTENAME([schema_name]) + N'.' + QUOTENAME(table_name) + N'''), ''' + redundant_index_name + N''', ''IsDisabled'') = 0 ALTER INDEX ' + QUOTENAME(redundant_index_name) + N' ON ' + QUOTENAME([schema_name]) + N'.' + QUOTENAME(table_name) + N' DISABLE;'
+ N' /* key columns: ' + red.redundant_key_columns + ISNULL(N', include: ' + red.redundant_include_columns, N'') + ISNULL(N', filter: ' + red.redundant_index_filter, N'') + N' */'
FROM #Results AS red
WHERE EXISTS
(
	SELECT red.[database_name], red.[schema_name], red.table_name, red.containing_index_name
	INTERSECT
	SELECT cont.[database_name], cont.[schema_name], cont.table_name, cont.containing_index_name
)
FOR XML PATH('')
), 1, 2, '')
, DropRedundantIndexes = 
STUFF((
SELECT 
N'; USE ' + QUOTENAME([database_name]) + N'; IF INDEXPROPERTY(OBJECT_ID(''' + QUOTENAME([schema_name]) + N'.' + QUOTENAME(table_name) + N'''), ''' + redundant_index_name + N''', ''IndexID'') IS NOT NULL DROP INDEX ' + QUOTENAME(redundant_index_name) + N' ON ' + QUOTENAME([schema_name]) + N'.' + QUOTENAME(table_name) + N';'
+ N' /* key columns: ' + red.redundant_key_columns + ISNULL(N', include: ' + red.redundant_include_columns, N'') + ISNULL(N', filter: ' + red.redundant_index_filter, N'') + N' */'
FROM #Results AS red
WHERE EXISTS
(
	SELECT red.[database_name], red.[schema_name], red.table_name, red.containing_index_name
	INTERSECT
	SELECT cont.[database_name], cont.[schema_name], cont.table_name, cont.containing_index_name
)
FOR XML PATH('')
), 1, 2, '')
FROM #Results AS cont
CROSS APPLY
(
	SELECT NewIncludeColumns = CASE WHEN containing_index_clustered = 0
	THEN
	STUFF((
		SELECT ', ' + includeColumn
		FROM
		(
			SELECT LTRIM(RTRIM(inc.[value])) AS includeColumn
			FROM string_split(cont.containing_include_columns, ',') AS inc
			
			UNION

			SELECT DISTINCT LTRIM(RTRIM(inc.[value])) AS includeColumn
			FROM #Results AS red
			CROSS APPLY string_split(red.redundant_include_columns, ',') AS inc
			WHERE EXISTS
			(
				SELECT red.[database_name], red.[schema_name], red.table_name, red.containing_index_name
				INTERSECT
				SELECT cont.[database_name], cont.[schema_name], cont.table_name, cont.containing_index_name
			)
			
			EXCEPT

			SELECT LTRIM(RTRIM(REPLACE(REPLACE([value], '] ASC', ']'), '] DESC', ']')))
			FROM string_split(cont.containing_key_columns,',')
		) AS include_columns
		FOR XML PATH ('')
	), 1, 2, '')
	ELSE NULL END
) AS incNew
WHERE NOT EXISTS
(SELECT NULL FROM #Results AS other WHERE EXISTS
	(
		SELECT other.[database_name], other.[schema_name], other.table_name, other.redundant_index_name
		INTERSECT
		SELECT cont.[database_name], cont.[schema_name], cont.table_name, cont.containing_index_name
	)
)
GROUP BY [database_name], [schema_name], table_name, containing_index_name, containing_key_columns, containing_include_columns
, containing_index_filter, containing_index_clustered, containing_index_unique, total_columns_count
, incNew.NewIncludeColumns
OPTION(RECOMPILE);

END

--DROP TABLE #Results;
