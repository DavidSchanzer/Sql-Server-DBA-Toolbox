-- Detect too many VLFs
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists all databases that have more than 1000 VLFs in their transaction log.
-- From: http://adventuresinsql.com/2009/12/a-busyaccidental-dbas-guide-to-managing-vlfs/

DECLARE @query VARCHAR(1000),
        @dbname VARCHAR(1000),
        @count INT;

SET NOCOUNT ON;

DECLARE csr CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
SELECT name
FROM sys.databases
WHERE state_desc = 'ONLINE';

CREATE TABLE ##loginfo
(
    dbname VARCHAR(100) NOT NULL,
    num_of_rows INT NOT NULL
);

OPEN csr;

FETCH NEXT FROM csr
INTO @dbname;

WHILE (@@fetch_status <> -1)
BEGIN

    CREATE TABLE #log_info
    (
        RecoveryUnitId TINYINT NOT NULL,
        fileid TINYINT NOT NULL,
        file_size BIGINT NOT NULL,
        start_offset BIGINT NOT NULL,
        FSeqNo INT NOT NULL,
        [status] TINYINT NOT NULL,
        parity TINYINT NOT NULL,
        create_lsn NUMERIC(25, 0) NOT NULL
    );

    SET @query = 'DBCC loginfo (' + '''' + @dbname + ''') ';

    INSERT INTO #log_info
    (
        RecoveryUnitId,
        fileid,
        file_size,
        start_offset,
        FSeqNo,
        status,
        parity,
        create_lsn
    )
    EXEC (@query);

    SET @count = @@rowcount;

    DROP TABLE #log_info;

    INSERT ##loginfo
    (
        dbname,
        num_of_rows
    )
    VALUES
    (@dbname, @count);

    FETCH NEXT FROM csr
    INTO @dbname;
END;

CLOSE csr;
DEALLOCATE csr;

SELECT dbname,
       num_of_rows
FROM ##loginfo
WHERE num_of_rows >= 1000
ORDER BY num_of_rows DESC;

DROP TABLE ##loginfo;
