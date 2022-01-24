-- Query the Default Trace
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script retrieves information from the Default Trace for the specified database and date/time range

SELECT TE.name AS EventName,
       T.TextData,
       T.DatabaseName,
       T.DatabaseID,
       T.NTDomainName,
       T.ApplicationName,
       T.LoginName,
       T.SPID,
       T.Duration,
       T.StartTime,
       T.EndTime
FROM sys.fn_trace_gettable(
                              LEFT(CONVERT(   VARCHAR(150),
                                   (
                                       SELECT TOP (1)
                                              f.value
                                       FROM sys.fn_trace_getinfo(NULL) AS f
                                       WHERE f.property = 2
                                   )
                                          ), CHARINDEX('log_',
                                                       CONVERT(   VARCHAR(150),
                                                       (
                                                           SELECT TOP (1)
                                                                  f.value
                                                           FROM sys.fn_trace_getinfo(NULL) AS f
                                                           WHERE f.property = 2
                                                       )
                                                              )
                                                      ) + 2) + '.trc',
                              DEFAULT
                          ) AS T
    JOIN sys.trace_events AS TE
        ON T.EventClass = TE.trace_event_id
WHERE T.StartTime
      BETWEEN '<StartDateTime>' AND '<EndDateTime>'
      AND T.DatabaseName = '<DatabaseName>'
ORDER BY T.StartTime;
