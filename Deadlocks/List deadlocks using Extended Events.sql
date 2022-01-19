;WITH SystemHealth
AS (
SELECT CAST(target_data AS xml) AS SessionXML
FROM sys.dm_xe_session_targets st
INNER JOIN sys.dm_xe_sessions s ON s.address = st.event_session_address
WHERE name = 'system_health'
)
SELECT Deadlock.value('@timestamp', 'datetime') AS DeadlockDateTime
,CAST(Deadlock.value('(data/value)[1]', 'varchar(max)') as xml) as DeadlockGraph
FROM SystemHealth s
CROSS APPLY SessionXML.nodes ('//RingBufferTarget/event') AS t (Deadlock)
WHERE Deadlock.value('@name', 'nvarchar(128)') = 'xml_deadlock_report';