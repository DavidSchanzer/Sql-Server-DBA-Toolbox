-- Capture execution plan warnings using Extended Events
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script creates an Extended Events session called "InterestingPlanEvents" that includes the following events that show as warnings on query plans:
--		missing_column_statistics
--		missing_join_predicate
--		plan_affecting_convert
--		unmatched_filtered_indexes
-- From https://sqlperformance.com/2015/10/extended-events/capture-plan-warnings

-- Remove event session if it exists
IF EXISTS (SELECT 1 FROM [sys].[server_event_sessions]
WHERE [name] = 'InterestingPlanEvents')
BEGIN
  DROP EVENT SESSION [InterestingPlanEvents] ON SERVER
END
GO
 
-- Define event session
CREATE EVENT SESSION [InterestingPlanEvents]
ON SERVER
ADD EVENT sqlserver.missing_column_statistics
(
  ACTION(sqlserver.database_id,sqlserver.plan_handle,sqlserver.sql_text)
  WHERE ([package0].[equal_boolean]([sqlserver].[is_system],(0))
    AND [sqlserver].[database_id]>(4))
),
ADD EVENT sqlserver.missing_join_predicate
(
  ACTION(sqlserver.database_id,sqlserver.plan_handle,sqlserver.sql_text)
  WHERE ([sqlserver].[is_system]=(0) AND [sqlserver].[database_id]>(4))
),
ADD EVENT sqlserver.plan_affecting_convert
(
  ACTION(sqlserver.database_id,sqlserver.plan_handle,sqlserver.sql_text)
  WHERE ([package0].[equal_boolean]([sqlserver].[is_system],(0))
    AND [sqlserver].[database_id]>(4))
),
ADD EVENT sqlserver.unmatched_filtered_indexes
(
  ACTION(sqlserver.plan_handle,sqlserver.sql_text)
  WHERE ([package0].[equal_boolean]([sqlserver].[is_system],(0))
    AND [sqlserver].[database_id]>(4))
)
ADD TARGET package0.event_file
(
  SET filename=N'C:\temp\InterestingPlanEvents' /* change location if appropriate */
)
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
MAX_DISPATCH_LATENCY=5 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,
TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)
GO
 
-- Start the event session
ALTER EVENT SESSION [InterestingPlanEvents] ON SERVER STATE=START;
GO
