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
FROM sys.fn_trace_gettable(LEFT(CONVERT(VARCHAR(150), (SELECT TOP (1) f.value FROM sys.fn_trace_getinfo(NULL) AS f WHERE f.property = 2)),
								   CHARINDEX('log_', CONVERT(VARCHAR(150), (SELECT TOP (1) f.value FROM sys.fn_trace_getinfo(NULL) AS f WHERE f.property = 2))) + 2) + '.trc',
                           DEFAULT) AS T
    JOIN sys.trace_events AS TE
        ON T.EventClass = TE.trace_event_id
WHERE T.StartTime
      BETWEEN '2022-01-10 16:00' AND '2022-01-10 17:00'
      AND T.DatabaseName = 'NAP_CONTENT'
      --AND T.ApplicationName NOT IN ( 'Spotlight Diagnostic Server (Monitoring)', 'SQLServerCEIP' )
ORDER BY T.StartTime;
