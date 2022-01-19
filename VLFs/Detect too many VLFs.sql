-- From: http://adventuresinsql.com/2009/12/a-busyaccidental-dbas-guide-to-managing-vlfs/

DECLARE @query VARCHAR(1000) ,
	@dbname VARCHAR(1000) ,
	@count INT

SET NOCOUNT ON

DECLARE csr CURSOR FAST_FORWARD READ_ONLY
FOR
	SELECT name
		FROM sys.databases
		WHERE state_desc = 'ONLINE'

CREATE TABLE ##loginfo
	(
	  dbname VARCHAR(100) ,
	  num_of_rows INT
	)

OPEN csr

FETCH NEXT FROM csr INTO @dbname

WHILE ( @@fetch_status <> -1 )
	BEGIN

		CREATE TABLE #log_info
			(
				RecoveryUnitId TINYINT ,
				fileid TINYINT ,
				file_size BIGINT ,
				start_offset BIGINT ,
				FSeqNo INT ,
				[status] TINYINT ,
				parity TINYINT ,
				create_lsn NUMERIC(25, 0)
			)

		SET @query = 'DBCC loginfo (' + '''' + @dbname + ''') '

		INSERT INTO #log_info
				EXEC ( @query )

		SET @count = @@rowcount

		DROP TABLE #log_info

		INSERT ##loginfo
			VALUES ( @dbname, @count )

		FETCH NEXT FROM csr INTO @dbname

	END

CLOSE csr
DEALLOCATE csr

SELECT dbname, num_of_rows
	FROM ##loginfo
	WHERE num_of_rows >= 1000
	ORDER BY num_of_rows DESC

DROP TABLE ##loginfo
