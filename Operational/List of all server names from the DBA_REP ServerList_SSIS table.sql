-- List of all server names from the DBA_REP ServerList_SSIS table
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script generates a distinct list of server names from the instances listed in the [DBA_Rep].[dbo].[ServerList_SSIS] table.

SELECT DISTINCT
       tb.value
FROM
(
    SELECT T.value
    FROM [DBA_Rep].[dbo].[ServerList_SSIS] AS S
        CROSS APPLY STRING_SPLIT([Server], '\') AS T
    WHERE T.value LIKE 'SV%'
          OR T.value LIKE 'UN%'
) AS dt
    CROSS APPLY STRING_SPLIT(value, '.') AS tb
WHERE tb.value LIKE 'SV%'
      OR tb.value LIKE 'UN%'
ORDER BY tb.value;
