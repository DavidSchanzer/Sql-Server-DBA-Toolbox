-- Who owns that #temp table
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script queries the Default Trace to determine which login created # tables in TempDB.
-- From http://sqlperformance.com/2014/05/t-sql-queries/dude-who-owns-that-temp-table

DECLARE @filename VARCHAR(MAX);
 
SELECT  @filename = SUBSTRING([path], 0,
                              LEN([path]) - CHARINDEX('\', REVERSE([path]))
                              + 1) + '\Log.trc'
FROM    sys.traces
WHERE   is_default = 1;  
 
SELECT  o.name,
        o.[object_id],
        o.create_date,
        gt.SPID,
        NTUserName = gt.NTDomainName + '\' + gt.NTUserName,
        SQLLogin = gt.LoginName,
        gt.HostName,
        gt.ApplicationName,
        gt.TextData -- don't bother, always NULL 
FROM    sys.fn_trace_gettable(@filename, DEFAULT) AS gt
        INNER JOIN tempdb.sys.objects AS o ON gt.ObjectID = o.[object_id]
WHERE   gt.DatabaseID = 2
        AND gt.EventClass = 46 -- (Object:Created Event from sys.trace_events)  
        AND gt.EventSubClass = 1 -- Commit
        AND o.name LIKE N'#%';
