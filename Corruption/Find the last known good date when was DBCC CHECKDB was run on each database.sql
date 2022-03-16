-- Find the last known good date when was DBCC CHECKDB was run on each database
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script uses DBCC DBINFO to retrieve the dbi_dbccLastKnownGood value to determine the date on which DBCC CHECKDB was last successfully
-- run on each database.
-- From https://www.sanssql.com/2011/03/t-sql-query-to-find-date-when-was-dbcc.html

CREATE TABLE #DBInfo
(
    Id INT IDENTITY(1, 1),
    ParentObject VARCHAR(255),
    [Object] VARCHAR(255),
    Field VARCHAR(255),
    [Value] VARCHAR(255)
);

CREATE TABLE #Value
(
    DatabaseName VARCHAR(255),
    LastDBCCCHeckDB_RunDate VARCHAR(255)
);

EXECUTE dbo.sp_foreachdb @command = 'INSERT INTO #DBInfo Execute (''DBCC DBINFO ( ''''?'''') WITH TABLERESULTS'');
INSERT INTO #Value (DatabaseName) SELECT [Value] FROM #DBInfo WHERE Field IN (''dbi_dbname'');
UPDATE #Value SET LastDBCCCHeckDB_RunDate = (SELECT TOP 1 [Value] FROM #DBInfo WHERE Field IN (''dbi_dbccLastKnownGood'')) where LastDBCCCHeckDB_RunDate is NULL;
TRUNCATE TABLE #DBInfo', @suppress_quotename = 1, @user_only = 1;

SELECT DatabaseName,
       LastDBCCCHeckDB_RunDate
FROM #Value;

DROP TABLE #DBInfo;
DROP TABLE #Value;
