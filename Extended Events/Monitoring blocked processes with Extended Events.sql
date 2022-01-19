--Monitoring Blocked Processes with Extended Events
--Source: "How to Use SQL Server’s Extended Events and Notifications to Proactively Resolve Performance Issues" by Jason Strate (Quest Software)
--
--Like deadlocks, blocked processes can also be monitored with extended events, though blocked processes aren’t already configured like the deadlock monitoring is above.
--To do this monitoring, you need to create an extended event session.
--
--There are two events that will be used with extended events:
--	sqlserver.locks_lock_timeouts: Number of times SQL Server waited on a row lock
--	sqlserver.locks_lock_waits: Total number of milliseconds SQL Server waited on a row lock
--
--The extended event session below can be built to capture blocking. This session will capture both events, along with the sql_text and tsql_stack actions.

CREATE EVENT SESSION BlockingTransactions ON SERVER
ADD EVENT sqlserver.lock_timeout (
    ACTION ( sqlserver.sql_text, sqlserver.tsql_stack ) ),
ADD EVENT sqlserver.locks_lock_waits (
    ACTION ( sqlserver.sql_text, sqlserver.tsql_stack ) )
ADD TARGET package0.ring_buffer
WITH (  MAX_DISPATCH_LATENCY = 30 SECONDS );
GO

ALTER EVENT SESSION BlockingTransactions ON SERVER STATE = START;
GO

--When blocking occurs, the information can be extracted from the session with the following query:
WITH    BlockingTransactions
          AS ( SELECT   CAST(target_data AS XML) AS SessionXML
               FROM     sys.dm_xe_session_targets st
                        INNER JOIN sys.dm_xe_sessions s ON s.address = st.event_session_address
               WHERE    name = 'BlockingTransactions'
             )
    SELECT  block.value('@timestamp', 'datetime') AS event_timestamp ,
            block.value('@name', 'nvarchar(128)') AS event_name ,
            block.value('(data/value)[1]', 'nvarchar(128)') AS event_count ,
            block.value('(data/value)[1]', 'nvarchar(128)') AS increment ,
            mv.map_value AS lock_type ,
            block.value('(action/value)[1]', 'nvarchar(max)') AS sql_text ,
            block.value('(action/value)[2]', 'nvarchar(255)') AS tsql_stack
    FROM    BlockingTransactions b
            CROSS APPLY SessionXML.nodes('//RingBufferTarget/event') AS t ( block )
            INNER JOIN sys.dm_xe_map_values mv ON block.value('(data/value)[3]',
                                                              'nvarchar(128)') = mv.map_key
                                                  AND name = 'lock_mode'
    WHERE   block.value('@name', 'nvarchar(128)') = 'locks_lock_waits'
    UNION ALL
    SELECT  block.value('@timestamp', 'datetime') AS event_timestamp ,
            block.value('@name', 'nvarchar(128)') AS event_name ,
            block.value('(data/value)[1]', 'nvarchar(128)') AS event_count ,
            NULL ,
            mv.map_value AS lock_type ,
            block.value('(action/value)[1]', 'nvarchar(max)') AS sql_text ,
            block.value('(action/value)[2]', 'nvarchar(255)') AS tsql_stack
    FROM    BlockingTransactions b
            CROSS APPLY SessionXML.nodes('//RingBufferTarget/event') AS t ( block )
            INNER JOIN sys.dm_xe_map_values mv ON block.value('(data/value)[2]',
                                                              'nvarchar(128)') = mv.map_key
                                                  AND name = 'lock_mode'
    WHERE   block.value('@name', 'nvarchar(128)') = 'locks_lock_timeouts';

--In the sample output above, a single lock occurred. The event had approximately 18K milliseconds of waiting. The locking was on an IU or intent to update. Added to that
--are the actions for sql_text and tsql_stack. The sql_text provides information on the SQL that was submitted in the transaction. Then the tsql_stack provides the stack
--of calls leading to the statement that encountered the blocking.
--
--This information could probably be collected and reported on in other ways. What makes this different from using event notifications is that it provides a lot of control
--over the details returned. The extended event session can be filtered to look at only certain databases, servers, users, etc. After a specified number of events, the event
--collection can be capped. If the actions included are not enough, more details can be added, such as session id, host name, application name, etc.
--
--Another advantage to using extended events is the opportunity to use multiple targets and collect information over time. For example, instead of the ring_buffer target,
--the sessions could be configured to use the asynchronous_bucketizer or synchronous_bucketizer target. With those targets, the transactions causing blocking can be grouped
--together and blocking patterns on specific statements can be seen. This flexibility allows for deep and meaningful blocking troubleshooting with minimal effort on the DBA’s
--part.
