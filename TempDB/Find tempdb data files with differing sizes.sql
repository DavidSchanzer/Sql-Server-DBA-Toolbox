-- Find tempdb data files with differing sizes
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script checks whether the sizes of all data files in the tempdb database, and produces an appropriate message accordingly.
-- Note that if the script detects differing file sizes and you execute the generated ALTER DATABASE statement to make them the same,
-- it's necessary to run the script below a second time to get it to generate another ALTER DATABASE statement with the files having the
-- same sizes, in order for these new file sizes to still apply after the next instance restart.

DECLARE @sql VARCHAR(MAX) = '', @maxsize BIGINT, @name VARCHAR(100)

SELECT files.name, stats.size_on_disk_bytes
INTO #sizes
FROM sys.dm_io_virtual_file_stats(2, NULL) as stats
INNER JOIN master.sys.master_files AS files 
	ON stats.database_id = files.database_id
	AND stats.file_id = files.file_id
WHERE files.type_desc = 'ROWS'
--AND files.name like 'tempdev%'

SELECT 'File sizes', STUFF((SELECT ', ' + CAST(size_on_disk_bytes AS VARCHAR) from #sizes FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,1,'')

SELECT @maxsize = MAX( size_on_disk_bytes ) FROM #sizes

DECLARE size_cur CURSOR LOCAL FAST_FORWARD FOR
	SELECT name FROM #sizes
	FOR READ ONLY

OPEN size_cur
FETCH size_cur INTO @name
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @sql = @sql + 'ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N''' + @name + ''', SIZE = ' + CAST( @maxsize / 1024 AS VARCHAR ) + 'KB ); '
	FETCH size_cur INTO @name
END
CLOSE size_cur
DEALLOCATE size_cur

IF ( SELECT COUNT( DISTINCT size_on_disk_bytes ) FROM #sizes ) > 1
	SELECT @@SERVERNAME + ' has different sizes', @sql
ELSE
	SELECT @@SERVERNAME + ' has the same sizes for tempdb data files', @sql

DROP TABLE #sizes
