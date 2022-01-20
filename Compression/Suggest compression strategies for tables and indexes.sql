-- Suggest compression strategies for tables and indexes
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script builds on Greg Low's script that suggests an appropriate Row, Page or Clustered Columnstore compression
-- From http://blog.greglow.com/2015/03/06/suggest-compression-strategies-for-tables-and-indexes/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE TABLE #Suggestions
(
    [DatabaseName] [sysname] NOT NULL,
    [SchemaName] [NVARCHAR](128) NULL,
    [TableName] [sysname] NOT NULL,
    [IndexName] [sysname] NULL,
    [PartitionNumber] [INT] NOT NULL,
    [CurrentCompression] [NVARCHAR](60) NULL,
    [SuggestedCompression] [NVARCHAR](11) NOT NULL,
    [Seeks] [BIGINT] NULL,
    [Scans] [BIGINT] NULL,
    [Updates] [BIGINT] NULL,
    [Operations] [BIGINT] NULL,
    [ScanPercentage] [INT] NULL,
    [PageCompressionScansCutoff] [INT] NULL,
    [UpdatePercentage] [INT] NULL,
    [PageCompressionUpdatesCutoff] [INT] NULL,
    [IndexType] [NVARCHAR](60) NULL,
    [Version] TINYINT NULL,
    [Edition] [NVARCHAR](60) NULL,
    [RequiresOfflineRebuild] BIT NULL,
    [ColumnstoreIndexOnTable] BIT NULL
);
GO

DECLARE @sql NVARCHAR(MAX);

SET @sql
    = N'
-----------------------------------------------------------------------------
-- Suggest data compression changes for tables and indexes
--
-- Dr Greg Low
-- March 2015
-- http://blog.greglow.com/2015/03/06/suggest-compression-strategies-for-tables-and-indexes/
--
-- CCI (Clustered Columnstore Index) will be recommended where the partition is scanned more than 95% of the time, updated less than 10% of the time,
--		seeks and lookups are less than 5% of the time, and where there are at least 800,000 rows. It will also only be recommended if it is supported.
-- PAGE will be recommended where the partition is scanned more than 75% of the time and updated less than 20% of the time.
-- ROW will be recommended in all other cases. We believe that ROW should be the default in SQL Server across the board, instead of NONE.
-- It is important that this script only be run after the system has been in use for long enough to have experienced typical usage patterns.
--
-----------------------------------------------------------------------------
DECLARE @ClusteredColumnstoreScansCutoff INT = 95;
DECLARE @ClusteredColumnstoreUpdatesCutoff INT = 10;
DECLARE @ClusteredColumnstoreSeeksLookupsCutoff INT = 5;
DECLARE @ClusteredColumnstoreTotalRowsCutoff BIGINT = 800000;
 
DECLARE @PageCompressionScansCutoff INT = 75;
DECLARE @PageCompressionUpdatesCutoff INT = 20;
DECLARE @IsClusteredColumnstoreSupported BIT = 1;
-----------------------------------------------------------------------------

WITH    IndexUsageStats
          AS ( SELECT   object_id AS ObjectID,
                        index_id AS IndexID,
                        COALESCE(user_seeks, 0) + COALESCE(system_seeks, 0) AS Seeks,
                        COALESCE(user_scans, 0) + COALESCE(system_scans, 0) AS Scans,
                        COALESCE(user_lookups, 0) + COALESCE(system_lookups, 0) AS Lookups,
                        COALESCE(user_updates, 0) + COALESCE(system_updates, 0) AS Updates,
                        COALESCE(user_seeks, 0) + COALESCE(system_seeks, 0)
                        + COALESCE(user_scans, 0) + COALESCE(system_scans, 0)
                        + COALESCE(user_lookups, 0) + COALESCE(system_lookups,
                                                              0)
                        + COALESCE(user_updates, 0) + COALESCE(system_updates,
                                                              0) AS Operations
               FROM     sys.dm_db_index_usage_stats
               WHERE    database_id = DB_ID()
             ),
        PartitionUsageDetails
          AS ( SELECT   SCHEMA_NAME(t.schema_id) AS SchemaName,
                        t.name AS TableName,
                        i.name AS IndexName,
                        i.index_id AS IndexID,
                        i.type_desc AS IndexType,
						ius.Seeks,
						ius.Scans,
						ius.Updates,
						ius.Operations,
                        CASE WHEN COALESCE(Operations, 0) <> 0
                             THEN CAST(( COALESCE(Seeks, 0) + COALESCE(Lookups,
                                                              0) ) * 100.0
                                  / COALESCE(Operations, 0) AS INT)
                             ELSE 0
                        END AS SeekLookupPercentage,
                        CASE WHEN COALESCE(Operations, 0) <> 0
                             THEN CAST(COALESCE(Scans, 0) * 100.0
                                  / COALESCE(Operations, 0) AS INT)
                             ELSE 0
                        END AS ScanPercentage,
                        CASE WHEN COALESCE(Operations, 0) <> 0
                             THEN CAST(COALESCE(Updates, 0) * 100.0
                                  / COALESCE(Operations, 0) AS INT)
                             ELSE 0
                        END AS UpdatePercentage,
                        p.partition_number AS PartitionNumber,
                        p.data_compression_desc AS CurrentCompression,
                        p.rows AS TotalRows, i.type_desc, t.object_id,
						CASE WHEN ( SELECT 1 FROM sys.indexes AS i2 WHERE i2.object_id = i.object_id AND i2.type IN (5,6)) = 1 THEN 1 ELSE 0 END AS ColumnstoreIndexOnTable
               FROM     sys.tables AS t
                        INNER JOIN sys.indexes AS i ON t.object_id = i.object_id
                        INNER JOIN sys.partitions AS p ON i.object_id = p.object_id
                                                          AND i.index_id = p.index_id
                        LEFT OUTER JOIN IndexUsageStats AS ius ON i.object_id = ius.ObjectID
                                                              AND i.index_id = ius.IndexID
               WHERE    t.is_ms_shipped = 0
                        AND t.type = N''U''
             ),
        SuggestedPartitionCompressionTypes
          AS ( SELECT   pud.*,
                        CASE WHEN pud.ScanPercentage >= @ClusteredColumnstoreScansCutoff
                                  AND pud.UpdatePercentage <= @ClusteredColumnstoreUpdatesCutoff
                                  AND pud.SeekLookupPercentage <= @ClusteredColumnstoreSeeksLookupsCutoff
                                  AND pud.TotalRows >= @ClusteredColumnstoreTotalRowsCutoff
                                  AND @IsClusteredColumnstoreSupported <> 0
                             THEN N''COLUMNSTORE''
                             WHEN pud.ScanPercentage >= @PageCompressionScansCutoff
                                  AND pud.UpdatePercentage <= @PageCompressionUpdatesCutoff
                             THEN N''PAGE''
                             ELSE N''ROW''
                        END AS SuggestedCompression
               FROM     PartitionUsageDetails AS pud
             )
    SELECT  ''?'' AS DatabaseName,
			spct.SchemaName,
            spct.TableName,
            spct.IndexName,
            spct.PartitionNumber,
            spct.CurrentCompression,
            spct.SuggestedCompression,
			spct.Seeks,
			spct.Scans,
			spct.Updates,
			spct.Operations,
            spct.ScanPercentage,
            @PageCompressionScansCutoff AS PageCompressionScansCutoff,
            spct.UpdatePercentage,
            @PageCompressionUpdatesCutoff AS PageCompressionUpdatesCutoff,
			spct.type_desc,
			CAST(SERVERPROPERTY(''ProductMajorVersion'') AS TINYINT) AS Version,
			CAST(SERVERPROPERTY(''Edition'') AS NVARCHAR(60)) AS Edition,
			CASE WHEN EXISTS
			( SELECT * FROM sys.columns AS c
				INNER JOIN sys.types AS t ON t.system_type_id = c.system_type_id
				WHERE c.object_id = spct.object_id AND
				(
					(t.name in (''VARCHAR'', ''NVARCHAR'') AND c.max_length = -1)	-- table has a (n)varchar(max) column
					OR t.name in (''TEXT'', ''NTEXT'', ''IMAGE'', ''VARBINARY'', ''XML'', ''FILESTREAM'')		-- table has a column that is one of these data types
				)
			) THEN 1 ELSE 0 END AS RequiresOfflineRebuild,
			spct.ColumnstoreIndexOnTable
    FROM    SuggestedPartitionCompressionTypes AS spct
    WHERE   spct.SuggestedCompression <> spct.CurrentCompression
		AND ( spct.CurrentCompression = ''NONE''
			OR ( spct.CurrentCompression = ''ROW'' AND spct.SuggestedCompression = ''PAGE'' ))
		AND NOT EXISTS
			( SELECT * FROM sys.columns AS c
				INNER JOIN sys.types AS t ON t.system_type_id = c.system_type_id
				WHERE c.object_id = spct.object_id
				  AND ( c.is_sparse = 1 OR c.is_column_set = 1 )	-- table has a column that is sparse or a column set
			)
    ORDER BY spct.SchemaName,
            spct.TableName,
            CASE WHEN spct.IndexID = 1 THEN 0
                 ELSE 1
            END,
            spct.IndexName;
';

INSERT INTO #Suggestions
(
    DatabaseName,
    SchemaName,
    TableName,
    IndexName,
    PartitionNumber,
    CurrentCompression,
    SuggestedCompression,
    Seeks,
    Scans,
    Updates,
    Operations,
    ScanPercentage,
    PageCompressionScansCutoff,
    UpdatePercentage,
    PageCompressionUpdatesCutoff,
    IndexType,
    Version,
    Edition,
    RequiresOfflineRebuild,
    ColumnstoreIndexOnTable
)
EXEC dbo.sp_ineachdb @command = @sql, @user_only = 1, @suppress_quotename = 1;

SELECT DatabaseName,
       SchemaName,
       TableName,
       IndexName,
       'USE [' + DatabaseName + ']; '
       + CASE
             WHEN IndexType IN ( 'CLUSTERED', 'HEAP' ) THEN
                 'ALTER TABLE [' + SchemaName + '].[' + TableName + '] REBUILD WITH (ONLINE = '
                 + CASE
                       WHEN Edition LIKE '%Standard%'
                            OR RequiresOfflineRebuild = 1 THEN
                           'OFF'
                       ELSE
                           'ON (WAIT_AT_LOW_PRIORITY (MAX_DURATION = 1 MINUTES, ABORT_AFTER_WAIT = SELF))'
                   END + ', DATA_COMPRESSION = ' + SuggestedCompression + ')'
             ELSE
                 'ALTER INDEX [' + IndexName + '] ON [' + SchemaName + '].[' + TableName + '] REBUILD WITH (ONLINE = '
                 + CASE
                       WHEN Edition LIKE '%Standard%'
                            OR ColumnstoreIndexOnTable = 1
                            OR RequiresOfflineRebuild = 1 THEN
                           'OFF'
                       ELSE
                           'ON (WAIT_AT_LOW_PRIORITY (MAX_DURATION = 1 MINUTES, ABORT_AFTER_WAIT = SELF))'
                   END + ', DATA_COMPRESSION = ' + SuggestedCompression + ')'
         END + ';' AS AlterStatement,
       PartitionNumber,
       CurrentCompression,
       SuggestedCompression,
       Seeks,
       Scans,
       Updates,
       Operations,
       ScanPercentage,
       PageCompressionScansCutoff,
       UpdatePercentage,
       PageCompressionUpdatesCutoff,
       IndexType,
       Version,
       Edition,
       RequiresOfflineRebuild,
       ColumnstoreIndexOnTable
FROM #Suggestions
WHERE NOT (
              Version = 12
              AND Edition LIKE '%Standard%'
          ) -- In SQL Server 2014, Standard Edition doesn't support compression
      AND
      (
          IndexName IS NULL
      ) -- For heap tables
ORDER BY DatabaseName,
         SchemaName,
         TableName,
         IndexName;

SELECT DatabaseName,
       COUNT(*) AS IndexCount
FROM #Suggestions
WHERE NOT (
              Version = 12
              AND Edition LIKE '%Standard%'
          ) -- In SQL Server 2014, Standard Edition doesn't support compression
      AND
      (
          IndexName IS NULL
      ) -- For heap tables
GROUP BY DatabaseName
ORDER BY DatabaseName;

SELECT COUNT(*) AS IndexCount
FROM #Suggestions
WHERE NOT (
              Version = 12
              AND Edition LIKE '%Standard%'
          ) -- In SQL Server 2014, Standard Edition doesn't support compression
      AND
      (
          IndexName IS NULL
      ) -- For heap tables
HAVING COUNT(*) > 0;

DROP TABLE #Suggestions;
