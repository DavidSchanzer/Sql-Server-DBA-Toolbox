-- Find all instances that have all databases offline (to be run against all instances using a Central Management Server)
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script displays "Active" if an instance has at least one user database online, and "Inactive" if all user databases are offline

SELECT CASE
           WHEN COUNT(*) > 0 THEN
               'Active'
           ELSE
               'Inactive'
       END AS Status
FROM sys.databases
WHERE state_desc = 'ONLINE'
      AND database_id > 4;
