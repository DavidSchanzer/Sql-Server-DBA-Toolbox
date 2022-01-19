-- Last user access to each database
SELECT d.name AS DBname,
       LastUserAccess =
       (
           SELECT LastUserAccess = MAX(a.xx)
           FROM
           (
               SELECT xx = MAX(last_user_seek)
               WHERE MAX(last_user_seek) IS NOT NULL
               UNION
               SELECT xx = MAX(last_user_scan)
               WHERE MAX(last_user_scan) IS NOT NULL
               UNION
               SELECT xx = MAX(last_user_lookup)
               WHERE MAX(last_user_lookup) IS NOT NULL
               UNION
               SELECT xx = MAX(last_user_update)
               WHERE MAX(last_user_update) IS NOT NULL
           ) a
       )
FROM master.dbo.sysdatabases d
    LEFT OUTER JOIN sys.dm_db_index_usage_stats s
        ON d.dbid = s.database_id
WHERE dbid > 4
GROUP BY d.name
ORDER BY LastUserAccess;

-- Last user access to a particular table
USE <DBName>;
SELECT d.name AS DBname,
       o.name AS [Table],
       LastUserAccess =
       (
           SELECT LastUserAccess = MAX(a.xx)
           FROM
           (
               SELECT xx = MAX([last_user_lookup])
               UNION
               SELECT xx = MAX([last_user_scan])
               UNION
               SELECT xx = MAX([last_user_seek])
               UNION
               SELECT xx = MAX([last_user_update])
           ) a
       )
FROM master.dbo.sysdatabases d
    INNER JOIN sys.dm_db_index_usage_stats s
        INNER JOIN sys.objects o
            ON o.object_id = s.object_id
        ON d.dbid = s.database_id
WHERE s.database_id = DB_ID()
      AND s.object_id = OBJECT_ID('<TableName>')
GROUP BY d.name,
         o.name;
