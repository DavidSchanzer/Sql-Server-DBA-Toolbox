-- Set notification for all jobs to email SQL Administrator
DECLARE @job_id UNIQUEIDENTIFIER;
DECLARE job_cur CURSOR LOCAL FAST_FORWARD FOR
SELECT job_id
FROM msdb.dbo.sysjobs;
--WHERE description = 'Source: http://ola.hallengren.com'
OPEN job_cur;
FETCH NEXT FROM job_cur
INTO @job_id;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC msdb.dbo.sp_update_job @job_id = @job_id,
                                @notify_level_email = 2,
                                @notify_level_netsend = 2,
                                @notify_level_page = 2,
                                @notify_email_operator_name = N'SQL Administrator';
    FETCH NEXT FROM job_cur
    INTO @job_id;
END;
CLOSE job_cur;
DEALLOCATE job_cur;
