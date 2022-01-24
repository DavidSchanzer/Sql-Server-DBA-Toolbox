-- Locks summary
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists summary information on the per-SPID locks currently held on this database

SELECT dtl.request_session_id,
       des.login_name,
       dtl.resource_type,
       (CASE
            WHEN dtl.resource_type = 'OBJECT' THEN
                OBJECT_NAME(dtl.resource_associated_entity_id)
            WHEN dtl.resource_type IN ( 'DATABASE', 'FILE', 'METADATA' ) THEN
                'N/A'
            WHEN dtl.resource_type IN ( 'KEY', 'PAGE', 'RID' ) THEN
            (
                SELECT OBJECT_NAME(object_id)
                FROM sys.partitions
                WHERE hobt_id = dtl.resource_associated_entity_id
            )
            ELSE
                'Undefined'
        END
       ) AS requested_object_name,
       dtl.request_mode AS lock_type,
       dtl.request_status,
       dtl.request_owner_id AS transaction_id
INTO #Locks
FROM sys.dm_tran_locks AS dtl
    LEFT OUTER JOIN sys.dm_exec_sessions AS des
        ON des.session_id = dtl.request_session_id;

SELECT request_session_id,
       login_name,
       resource_type,
       requested_object_name,
       lock_type,
       request_status,
       transaction_id,
       COUNT(*) AS [Lock Count]
FROM #Locks
GROUP BY request_session_id,
         login_name,
         resource_type,
         requested_object_name,
         lock_type,
         request_status,
         transaction_id
ORDER BY request_session_id,
         login_name,
         resource_type,
         requested_object_name,
         lock_type,
         request_status,
         transaction_id;

DROP TABLE #Locks;
