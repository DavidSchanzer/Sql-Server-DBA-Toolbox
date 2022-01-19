USE [WaitsAndQueuesPerformanceAnalysis]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[WaitingTasks](
	[curr_datetime] [datetime] NOT NULL,
	[session_id] [smallint] NULL,
	[exec_context_id] [int] NULL,
	[wait_duration_ms] [bigint] NULL,
	[wait_type] [nvarchar](60) NULL,
	[blocking_session_id] [smallint] NULL,
	[resource_description] [nvarchar](2048) NULL,
	[program_name] [nvarchar](128) NULL,
	[text] [nvarchar](max) NULL,
	[dbid] [smallint] NULL,
	[query_plan] [xml] NULL,
	[cpu_time] [int] NOT NULL,
	[memory_usage] [int] NOT NULL
)

GO

INSERT INTO [WaitsAndQueuesPerformanceAnalysis].[dbo].[WaitingTasks]
           ([curr_datetime]
           ,[session_id]
           ,[exec_context_id]
           ,[wait_duration_ms]
           ,[wait_type]
           ,[blocking_session_id]
           ,[resource_description]
           ,[program_name]
           ,[text]
           ,[dbid]
           ,[query_plan]
           ,[cpu_time]
           ,[memory_usage])
SELECT
	GETDATE() AS curr_datetime,
	owt.session_id,
	owt.exec_context_id,
	owt.wait_duration_ms,
	owt.wait_type,
	owt.blocking_session_id,
	owt.resource_description,
	es.program_name,
	est.text,
	est.dbid,
	eqp.query_plan,
	es.cpu_time,
	es.memory_usage
FROM sys.dm_os_waiting_tasks AS owt
INNER JOIN sys.dm_exec_sessions AS es ON owt.session_id = es.session_id
INNER JOIN sys.dm_exec_requests AS er ON es.session_id = er.session_id
OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) AS est
OUTER APPLY sys.dm_exec_query_plan(er.plan_handle) AS eqp
WHERE   es.is_user_process = 1
        AND owt.wait_type NOT IN ( 'BROKER_EVENTHANDLER',
                                   'BROKER_RECEIVE_WAITFOR',
                                   'BROKER_TASK_STOP',
								   'BROKER_TO_FLUSH',
                                   'BROKER_TRANSMITTER',
								   'CHECKPOINT_QUEUE',
                                   'CLR_AUTO_EVENT',
								   'CLR_MANUAL_EVENT',
                                   'CLR_SEMAPHORE',
								   'DBMIRROR_EVENTS_QUEUE',
                                   'DBMIRRORING_CMD',
								   'DIRTY_PAGE_POLL',
                                   'DISPATCHER_QUEUE_SEMAPHORE',
                                   'FT_IFTS_SCHEDULER_IDLE_WAIT',
                                   'FT_IFTSHC_MUTEX',
                                   'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
                                   'LAZYWRITER_SLEEP',
								   'LOGMGR_QUEUE',
                                   'ONDEMAND_TASK_QUEUE',
                                   'REQUEST_FOR_DEADLOCK_SEARCH',
                                   'RESOURCE_QUEUE',
								   'SLEEP_BPOOL_FLUSH',
                                   'SLEEP_SYSTEMTASK',
								   'SLEEP_TASK',
                                   'SP_SERVER_DIAGNOSTICS_SLEEP',
                                   'SQLTRACE_BUFFER_FLUSH',
                                   'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
                                   'SQLTRACE_LOCK',
								   'SQLTRACE_WAIT_ENTRIES',
                                   'TRACEWRITE',
								   'WAITFOR',
                                   'XE_DISPATCHER_JOIN',
								   'XE_DISPATCHER_WAIT',
                                   'XE_TIMER_EVENT' )
AND ( est.dbid > 4 AND est.dbid != 32767 AND est.dbid != DB_ID( 'distribution' ) AND es.program_name NOT LIKE 'SQLAgent - %' )
ORDER BY owt.session_id,
        owt.exec_context_id
