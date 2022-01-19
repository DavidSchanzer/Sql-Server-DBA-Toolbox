SET NOCOUNT ON;

-- 1. Update the schedule for the Full backup job to a random day of the week and a random time between 7pm and 11pm
DECLARE @schedule_id INT,
        @freq_interval INT,
        @random_time INT,
        @job_id UNIQUEIDENTIFIER,
        @name sysname,
        @command NVARCHAR(MAX),
        @message VARCHAR(1000);

-- To generate a random integer between @Upper and @Lower: ROUND(((@Upper - @Lower) * RAND() + @Lower), 0)
SET @freq_interval = CASE ROUND(((7 - 1) * RAND() + 1), 0) -- Generate a random integer between 1 and 7
                         WHEN 1 THEN
                             1  -- Sunday
                         WHEN 2 THEN
                             2  -- Monday
                         WHEN 3 THEN
                             4  -- Tuesday
                         WHEN 4 THEN
                             8  -- Wednesday
                         WHEN 5 THEN
                             16 -- Thursday
                         WHEN 6 THEN
                             32 -- Friday
                         ELSE
                             64 -- Saturday
                     END;

SET @random_time = ROUND(((23 - 19) * RAND() + 19), 0) * 10000; -- Generate a random integer between 19 and 23 (ie. 7pm to 11pm), multiplied by 10000 to add 4 zeroes (for mins and secs)

SELECT @schedule_id = [sjs].[schedule_id]
FROM [msdb].[dbo].[sysjobs] AS [sj]
    INNER JOIN [msdb].[dbo].[sysjobschedules] AS [sjs]
        ON [sj].[job_id] = [sjs].[job_id]
WHERE [sj].[name] = 'DatabaseBackup - USER_DATABASES - FULL';

SET @message = 'Full database backup job: updated schedule to ' + CASE @freq_interval
                                                                      WHEN 1 THEN
                                                                          'Sunday'
                                                                      WHEN 2 THEN
                                                                          'Monday'
                                                                      WHEN 4 THEN
                                                                          'Tuesday'
                                                                      WHEN 8 THEN
                                                                          'Wednesday'
                                                                      WHEN 16 THEN
                                                                          'Thursday'
                                                                      WHEN 32 THEN
                                                                          'Friday'
                                                                      ELSE
                                                                          'Saturday'
                                                                  END + ' at ' + CAST(@random_time AS CHAR(6));
PRINT @message;

-- 2. Update the schedule for the Differential backup job to every day and a random time between 7pm and 11pm
EXEC [msdb].[dbo].[sp_update_schedule] @schedule_id = @schedule_id,
                                       @new_name = N'Full database backup schedule',
                                       @enabled = 1,
                                       @freq_type = 8,
                                       @freq_interval = @freq_interval,
                                       @freq_subday_type = 1,
                                       @freq_subday_interval = 0,
                                       @freq_relative_interval = 0,
                                       @freq_recurrence_factor = 1,
                                       @active_start_date = 20130531,
                                       @active_end_date = 99991231,
                                       @active_start_time = @random_time,
                                       @active_end_time = 235959;

SET @random_time = ROUND(((23 - 19) * RAND() + 19), 0) * 10000; -- Generate a random integer between 19 and 23 (ie. 7pm to 11pm), multiplied by 10000 to add 4 zeroes (for mins and secs)

SELECT @schedule_id = [sjs].[schedule_id]
FROM [msdb].[dbo].[sysjobs] AS [sj]
    INNER JOIN [msdb].[dbo].[sysjobschedules] AS [sjs]
        ON [sj].[job_id] = [sjs].[job_id]
WHERE [sj].[name] = 'DatabaseBackup - USER_DATABASES - DIFF';

EXEC [msdb].[dbo].[sp_update_schedule] @schedule_id = @schedule_id,
                                       @new_name = N'Every evening',
                                       @enabled = 1,
                                       @freq_type = 4,
                                       @freq_interval = 1,
                                       @freq_subday_type = 1,
                                       @freq_subday_interval = 0,
                                       @freq_relative_interval = 0,
                                       @freq_recurrence_factor = 1,
                                       @active_start_date = 20130531,
                                       @active_end_date = 99991231,
                                       @active_start_time = @random_time,
                                       @active_end_time = 235959;

SET @message = 'Differential database backup job: updated schedule to every day at ' + CAST(@random_time AS CHAR(6));
PRINT @message;

-- 3. Update the @Directory parameter for all Ola Hallengren database backup jobs from <FromValue> to <ToValue>
DECLARE @test TABLE
(
    [step_id] INT NULL,
    [step_name] sysname NULL,
    [subsystem] NVARCHAR(40) NULL,
    [command] NVARCHAR(MAX) NULL,
    [flags] INT NULL,
    [cmdexec_success_code] INT NULL,
    [on_success_action] TINYINT NULL,
    [on_success_step_id] INT NULL,
    [on_fail_action] TINYINT NULL,
    [on_fail_step_id] INT NULL,
    [server] sysname NULL,
    [database_name] sysname NULL,
    [database_user_name] sysname NULL,
    [retry_attempts] INT NULL,
    [retry_interval] INT NULL,
    [os_run_priority] INT NULL,
    [output_file_name] NVARCHAR(200) NULL,
    [last_run_outcome] INT NULL,
    [last_run_duration] INT NULL,
    [last_run_retries] INT NULL,
    [last_run_date] INT NULL,
    [last_run_time] INT NULL,
    [proxy_id] INT NULL
);

DECLARE [job_cur] CURSOR LOCAL FAST_FORWARD FOR
SELECT [job_id],
       [name]
FROM [msdb].[dbo].[sysjobs]
WHERE [name] LIKE 'DatabaseBackup%'
FOR READ ONLY;

OPEN [job_cur];

FETCH [job_cur]
INTO @job_id,
     @name;

WHILE @@FETCH_STATUS = 0
BEGIN
    DELETE FROM @test;

    INSERT INTO @test
    EXEC [msdb].[dbo].[sp_help_jobstep] @job_id = @job_id, @step_id = 1;

    SELECT @command = [command]
    FROM @test;

    IF CHARINDEX(N'<FromValue>', @command) > 0
    BEGIN
        SET @command = REPLACE(@command, N'<FromValue>', N'<ToValue>');

        EXEC [msdb].[dbo].[sp_update_jobstep] @job_id = @job_id,
                                              @step_id = 1,
                                              @command = @command;

        SET @message = @name + ':  updated command to ' + @command;
        PRINT @message;
    END;

    FETCH [job_cur]
    INTO @job_id,
         @name;
END;

CLOSE [job_cur];
DEALLOCATE [job_cur];
