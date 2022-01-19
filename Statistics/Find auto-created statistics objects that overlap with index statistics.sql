EXEC dbo.sp_foreachdb @command = 'USE ?;
WITH    autostats ( object_id, stats_id, name, column_id )
			AS ( SELECT   sys.stats.object_id ,
						sys.stats.stats_id ,
						sys.stats.name ,
						sys.stats_columns.column_id
				FROM     sys.stats
						INNER JOIN sys.stats_columns ON sys.stats.object_id = sys.stats_columns.object_id
														AND sys.stats.stats_id = sys.stats_columns.stats_id
				WHERE    sys.stats.auto_created = 1
						AND sys.stats_columns.stats_column_id = 1
				)
	SELECT  OBJECT_NAME(sys.stats.object_id) AS [Table] ,
			sys.columns.name AS [Column] ,
			sys.stats.name AS [Overlapped] ,
			autostats.name AS [Overlapping] ,
			''DROP STATISTICS ['' + OBJECT_SCHEMA_NAME(sys.stats.object_id) + ''].['' + OBJECT_NAME(sys.stats.object_id) + ''].['' + autostats.name + '']'' AS Drop_Statement
	INTO #Tmp
	FROM    sys.stats
			INNER JOIN sys.stats_columns ON sys.stats.object_id = sys.stats_columns.object_id
											AND sys.stats.stats_id = sys.stats_columns.stats_id
			INNER JOIN autostats ON sys.stats_columns.object_id = autostats.object_id
									AND sys.stats_columns.column_id = autostats.column_id
			INNER JOIN sys.columns ON sys.stats.object_id = sys.columns.object_id
										AND sys.stats_columns.column_id = sys.columns.column_id
	WHERE   sys.stats.auto_created = 0
			AND sys.stats_columns.stats_column_id = 1
			AND sys.stats_columns.stats_id != autostats.stats_id
			AND OBJECTPROPERTY(sys.stats.object_id, ''IsMsShipped'') = 0
			AND sys.stats.has_filter = 0;

--SELECT * FROM #Tmp;
SELECT DISTINCT ''USE ['' + DB_NAME() + '']; '' + Drop_Statement + '';'' AS Distinct_Drop_Statements FROM #Tmp;
DROP TABLE #Tmp;
', @user_only = 1
