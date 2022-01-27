-- Last user access to each database
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script contains 2 SELECT statements.
-- The first shows the last access date & time for each user database on the instance, using then last_user_% columns in
-- dm_db_index_usage_stats.
-- The second shows the last access date & time for a nominated table, using the same method.

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
WHERE d.dbid > 4
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
