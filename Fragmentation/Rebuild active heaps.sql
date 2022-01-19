SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

CREATE TABLE #ActiveHeaps
(
    DatabaseName sysname NOT NULL,
    SchemaName NVARCHAR(128) NULL,
    TableName sysname NOT NULL,
    Edition NVARCHAR(60) NOT NULL,
    RequiresOfflineRebuild TINYINT NOT NULL,
	ForwardedFetchCount BIGINT NOT NULL
);

DECLARE @Execute BIT = 0,
        @DBID INT,
        @MaxDBID INT,
        @database_id INT,
        @DBName sysname,
        @TableName sysname,
        @SchemaName sysname,
        @TableID INT,
        @MaxTableID INT,
        @ForwardedFetchCount BIGINT,
        @SQL VARCHAR(500),
		@RequiresOfflineRebuildSQL NVARCHAR(500),
		@RequiresOfflineRebuildResult TINYINT,
        @FullyQualifiedObjectName VARCHAR(500);

DECLARE @DB TABLE
(
    DBID INT IDENTITY NOT NULL PRIMARY KEY,
    database_id INT NOT NULL,
    DBName sysname NOT NULL,
    MaxLastUserScanOnHeap DATETIME2 NULL
);
CREATE TABLE #Table
(
    TableID INT IDENTITY NOT NULL PRIMARY KEY,
    SchemaName sysname NOT NULL,
    TableName sysname NOT NULL,
    ForwardedFetchCount BIGINT NOT NULL
);

-- Find the DBs that have heap scans in the last 7 days, order by most recently scanned DBs
INSERT INTO @DB
(
    database_id,
    DBName,
    MaxLastUserScanOnHeap
)
SELECT ddius.database_id,
       DB_NAME(ddius.database_id) AS DBName,
       MAX(ddius.last_user_scan) AS MaxLastUserScanOnHeap
FROM sys.dm_db_index_usage_stats AS ddius
WHERE ddius.database_id > 4
      AND ddius.index_id = 0 -- Heap
GROUP BY ddius.database_id,
         DB_NAME(ddius.database_id)
HAVING MAX(ddius.last_user_scan) > DATEADD(DAY, -7, SYSDATETIME())
ORDER BY MAX(ddius.last_user_scan) DESC;

SELECT @DBID = 1,
       @MaxDBID = COALESCE(MAX(d.DBID), 0)
FROM @DB AS d;

WHILE @DBID <= @MaxDBID
BEGIN
    SELECT @database_id = d.database_id,
           @DBName = d.DBName
    FROM @DB AS d
    WHERE d.DBID = @DBID;

    -- First, clean out our table list to start fresh.
    TRUNCATE TABLE #Table;

    -- Get the heaps scanned in the last 7 days that have forward fetch counts > 0
    INSERT #Table
    (
        SchemaName,
        TableName,
        ForwardedFetchCount
    )
    SELECT OBJECT_SCHEMA_NAME(ddius.object_id, ddius.database_id) AS SchemaName,
           OBJECT_NAME(ddius.object_id, ddius.database_id) AS TableName,
           ddios.forwarded_fetch_count
    FROM sys.dm_db_index_usage_stats AS ddius
        CROSS APPLY sys.dm_db_index_operational_stats(ddius.database_id, ddius.object_id, 0, DEFAULT) AS ddios
    WHERE ddius.database_id = @database_id
          AND ddius.index_id = 0
          -- Let's narrow this down to ones that have user scans in the last week 
          AND ddius.last_user_scan > DATEADD(DAY, -7, SYSDATETIME())
          -- and non-zero forwarded fetch count
          AND ddios.forwarded_fetch_count > 0
    ORDER BY ddios.forwarded_fetch_count DESC;

    -- Loop on each table
    SELECT @TableID = 1,
           @MaxTableID = MAX(TableID)
    FROM #Table;

    WHILE @TableID <= @MaxTableID
    BEGIN
        SELECT @SchemaName = t.SchemaName,
               @TableName = t.TableName,
               @ForwardedFetchCount = t.ForwardedFetchCount
        FROM #Table AS t
        WHERE t.TableID = @TableID;

        SET @FullyQualifiedObjectName = '[' + @DBName + '].[' + @SchemaName + '].[' + @TableName + ']';
		SET @RequiresOfflineRebuildSQL = N'USE [' + CAST(@DBName AS NVARCHAR(128)) + N']; SELECT @RequiresOfflineRebuildResult = CASE WHEN EXISTS
				( SELECT * FROM sys.columns AS c
					INNER JOIN sys.types AS t ON t.system_type_id = c.system_type_id
					WHERE c.object_id = OBJECT_ID(''' + CAST(@FullyQualifiedObjectName AS NVARCHAR(128)) + N''') AND
					(
						(t.name in (''VARCHAR'', ''NVARCHAR'') AND c.max_length = -1)
						OR t.name in (''TEXT'', ''NTEXT'', ''IMAGE'', ''VARBINARY'', ''XML'', ''FILESTREAM'')
					)
				) THEN 1 ELSE 0 END;';
		EXECUTE sp_executesql @RequiresOfflineRebuildSQL, N'@RequiresOfflineRebuildResult TINYINT OUTPUT', @RequiresOfflineRebuildResult = @RequiresOfflineRebuildResult OUTPUT;

		INSERT INTO #ActiveHeaps
			(DatabaseName, SchemaName, TableName, Edition, RequiresOfflineRebuild, ForwardedFetchCount)
		VALUES
			(@DBName, @SchemaName, @TableName, CAST(SERVERPROPERTY('Edition') AS NVARCHAR(60)), @RequiresOfflineRebuildResult, @ForwardedFetchCount);

        SET @TableID = @TableID + 1;
    END;

    SET @DBID = @DBID + 1;
END;

DECLARE heap_cur CURSOR FOR
	SELECT 'USE [' + DatabaseName + ']; ' +
		   'ALTER TABLE [' + SchemaName + '].[' + TableName + '] REBUILD WITH (ONLINE = '
					 + CASE
						   WHEN Edition LIKE '%Standard%' OR RequiresOfflineRebuild = 1 THEN
							   'OFF'
						   ELSE
							   'ON (WAIT_AT_LOW_PRIORITY (MAX_DURATION = 1 MINUTES, ABORT_AFTER_WAIT = SELF))'
					   END + ');	-- Forwarded fetch count = ' + CAST(ForwardedFetchCount AS VARCHAR(10)) AS AlterStatement
	FROM #ActiveHeaps
	WHERE ForwardedFetchCount > 100000
	ORDER BY DatabaseName,
			 SchemaName,
			 TableName
	FOR READ ONLY;

OPEN heap_cur;

FETCH heap_cur INTO @SQL;

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @SQL;
	--EXEC (@SQL);

	FETCH heap_cur INTO @SQL;
END

CLOSE heap_cur;
DEALLOCATE heap_cur;

DROP TABLE #Table;
DROP TABLE #ActiveHeaps
GO
