-- List all extended events sessions and whether they are running
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists the name of the Extended Events session and either 'Running' or 'Stopped'.

SELECT ses.name,
       CASE
           WHEN dxs.name IS NULL THEN
               'Stopped'
           ELSE
               'Running'
       END AS State
FROM sys.server_event_sessions AS ses
    LEFT OUTER JOIN sys.dm_xe_sessions AS dxs
        ON ses.name = dxs.name;
