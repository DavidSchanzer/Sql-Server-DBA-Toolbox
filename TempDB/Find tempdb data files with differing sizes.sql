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
