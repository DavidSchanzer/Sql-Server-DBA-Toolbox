CREATE TABLE #output (DBName sysname, TableName sysname, reserved BIGINT);
INSERT INTO #output EXEC sp_ineachdb 'SELECT TOP (1) db_name(), object_name(id), reserved FROM sysindexes WHERE indid = 1 ORDER BY reserved DESC';
SELECT * FROM #output;
DROP TABLE #output;
