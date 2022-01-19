SELECT CASE
           WHEN COUNT(*) > 0 THEN
               'Active'
           ELSE
               'Inactive'
       END AS Status
FROM sys.databases
WHERE state_desc = 'ONLINE'
      AND database_id > 4;
