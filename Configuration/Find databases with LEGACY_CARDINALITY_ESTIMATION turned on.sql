CREATE TABLE #dbs
(
    [dbname] sysname NOT NULL,
    value SQL_VARIANT NOT NULL
);

INSERT INTO #dbs
EXEC sp_ineachdb 'SELECT DB_NAME(DB_ID()), value FROM sys.database_scoped_configurations WHERE name = ''LEGACY_CARDINALITY_ESTIMATION'' AND value = 1';

SELECT *
FROM #dbs;

DROP TABLE #dbs;
