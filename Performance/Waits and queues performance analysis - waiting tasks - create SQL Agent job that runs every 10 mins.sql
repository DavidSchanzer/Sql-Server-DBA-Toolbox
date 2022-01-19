USE [msdb]
GO

/****** Object:  Job [Waiting Tasks Logging]    Script Date: 5/10/2012 12:16:34 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Data Collector]    Script Date: 5/10/2012 12:16:34 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Data Collector' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Data Collector'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Waiting Tasks Logging', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Data Collector', 
		@owner_login_name=N'CI\DSCHA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Collect]    Script Date: 5/10/2012 12:16:34 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Collect', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'INSERT INTO [WaitsAndQueuesPerformanceAnalysis].[dbo].[WaitingTasks]
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
        AND owt.wait_type NOT IN ( ''BROKER_EVENTHANDLER'',
                                   ''BROKER_RECEIVE_WAITFOR'',
                                   ''BROKER_TASK_STOP'',
								   ''BROKER_TO_FLUSH'',
                                   ''BROKER_TRANSMITTER'',
								   ''CHECKPOINT_QUEUE'',
                                   ''CLR_AUTO_EVENT'',
								   ''CLR_MANUAL_EVENT'',
                                   ''CLR_SEMAPHORE'',
								   ''DBMIRROR_EVENTS_QUEUE'',
                                   ''DBMIRRORING_CMD'',
								   ''DIRTY_PAGE_POLL'',
                                   ''DISPATCHER_QUEUE_SEMAPHORE'',
                                   ''FT_IFTS_SCHEDULER_IDLE_WAIT'',
                                   ''FT_IFTSHC_MUTEX'',
                                   ''HADR_FILESTREAM_IOMGR_IOCOMPLETION'',
                                   ''LAZYWRITER_SLEEP'',
								   ''LOGMGR_QUEUE'',
                                   ''ONDEMAND_TASK_QUEUE'',
                                   ''REQUEST_FOR_DEADLOCK_SEARCH'',
                                   ''RESOURCE_QUEUE'',
								   ''SLEEP_BPOOL_FLUSH'',
                                   ''SLEEP_SYSTEMTASK'',
								   ''SLEEP_TASK'',
                                   ''SP_SERVER_DIAGNOSTICS_SLEEP'',
                                   ''SQLTRACE_BUFFER_FLUSH'',
                                   ''SQLTRACE_INCREMENTAL_FLUSH_SLEEP'',
                                   ''SQLTRACE_LOCK'',
								   ''SQLTRACE_WAIT_ENTRIES'',
                                   ''TRACEWRITE'',
								   ''WAITFOR'',
                                   ''XE_DISPATCHER_JOIN'',
								   ''XE_DISPATCHER_WAIT'',
                                   ''XE_TIMER_EVENT'' )
AND ( est.dbid > 4 AND est.dbid != 32767 AND est.dbid != DB_ID( ''distribution'' ))
ORDER BY owt.session_id,
        owt.exec_context_id
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 10 mins', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=62, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20120907, 
		@active_end_date=99991231, 
		@active_start_time=80000, 
		@active_end_time=170000, 
		@schedule_uid=N'484ed966-c5b7-4b24-befb-529cd9e4941f'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


