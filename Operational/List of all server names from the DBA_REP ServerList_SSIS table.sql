SELECT DISTINCT
       tb.value
FROM
(
    SELECT value
    FROM [DBA_Rep].[dbo].[ServerList_SSIS]
        CROSS APPLY STRING_SPLIT([Server], '\')
    WHERE value LIKE 'SV%'
          OR value LIKE 'UN%'
) AS dt
    CROSS APPLY STRING_SPLIT(value, '.') AS tb
WHERE tb.value LIKE 'SV%'
      OR tb.value LIKE 'UN%'
ORDER BY tb.value;
