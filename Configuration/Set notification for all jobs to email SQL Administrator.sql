-- Set notification for all jobs that currently have no notification to email SQL Administrator
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script sets notification for all SQL Agent jobs to email SQL Administrator

DECLARE @job_id UNIQUEIDENTIFIER;

DECLARE job_cur CURSOR LOCAL FAST_FORWARD FOR
SELECT job_id
FROM msdb.dbo.sysjobs
WHERE notify_level_email = 0;

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
