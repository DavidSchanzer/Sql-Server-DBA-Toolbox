-- List deadlocks using the system_health Extended Events session
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script queries the default system_health Extended Events session for deadlocks, returning the output in XML

;WITH SystemHealth
AS (SELECT CAST(st.target_data AS XML) AS SessionXML
    FROM sys.dm_xe_session_targets st
        INNER JOIN sys.dm_xe_sessions s
            ON s.address = st.event_session_address
    WHERE s.name = 'system_health')
SELECT Deadlock.value('@timestamp', 'datetime') AS DeadlockDateTime,
       CAST(Deadlock.value('(data/value)[1]', 'varchar(max)') AS XML) AS DeadlockGraph
FROM SystemHealth s
    CROSS APPLY SessionXML.nodes('//RingBufferTarget/event') AS t(Deadlock)
WHERE Deadlock.value('@name', 'nvarchar(128)') = 'xml_deadlock_report';
