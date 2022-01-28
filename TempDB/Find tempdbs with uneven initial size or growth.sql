-- Find tempdbs with uneven initial size or growth
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script generates an explanatory sentence if there are multiple size, growth or is_percent_growth values on tempdb data files.

SELECT 'The tempdb database has multiple data files in one filegroup, but they are not all set up with the same initial size or to grow in identical amounts.  This can lead to uneven file activity inside the filegroup.'
FROM tempdb.sys.database_files
WHERE type_desc = 'ROWS'
GROUP BY data_space_id
HAVING COUNT(DISTINCT size) > 1
       OR COUNT(DISTINCT growth) > 1
       OR COUNT(DISTINCT is_percent_growth) > 1;
