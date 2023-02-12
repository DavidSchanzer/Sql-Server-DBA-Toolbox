-- List all database extended properties Application Name and Owner
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script extracts, for all user databases, the database extended properties "Application Name" and "Owner" which we keep on each database.

IF OBJECT_ID('tempdb..#results') IS NOT NULL DROP TABLE #results;
CREATE TABLE #results
(
    DatabaseName sysname NOT NULL,
    ApplicationName sysname NULL,
    Owner sysname NULL
);

INSERT INTO #results
EXEC sp_ineachdb '
IF OBJECT_ID(''tempdb..#dbs'') IS NOT NULL DROP TABLE #dbs;
IF OBJECT_ID(''tempdb..#props'') IS NOT NULL DROP TABLE #props;

CREATE TABLE #dbs
(
    DatabaseName sysname NOT NULL
);

INSERT INTO #dbs
(
    DatabaseName
)
SELECT DB_NAME() AS DatabaseName;

CREATE TABLE #props
(
    DatabaseName sysname NOT NULL,
    PropertyName sysname NULL,
    PropertyValue sysname NULL
);

INSERT INTO #props
(
    DatabaseName,
    PropertyName,
    PropertyValue
)
SELECT DB_NAME() AS DatabaseName,
       name AS PropertyName,
       CAST(value AS sysname) AS PropertyValue
FROM sys.extended_properties
WHERE class_desc = ''DATABASE''
      AND name IN ( ''Application Name'', ''Owner'' );

INSERT INTO #results
(
    DatabaseName,
    ApplicationName,
    Owner
)
SELECT pivot_table.DatabaseName,
       pivot_table.[Application Name],
       pivot_table.Owner
FROM
(
    SELECT d.DatabaseName,
           p.PropertyName,
           p.PropertyValue
    FROM #dbs AS d
        LEFT OUTER JOIN #props AS p
            ON d.DatabaseName = p.DatabaseName
) t
PIVOT
(
    MIN(PropertyValue)
    FOR PropertyName IN ([Application Name], Owner)
) AS pivot_table;
',
@user_only = 1;

SELECT DatabaseName,
       ApplicationName,
       Owner
FROM #results
WHERE 
ApplicationName IS NULL OR ApplicationName = ''
OR Owner IS NULL OR Owner = ''
ORDER BY DatabaseName
;
