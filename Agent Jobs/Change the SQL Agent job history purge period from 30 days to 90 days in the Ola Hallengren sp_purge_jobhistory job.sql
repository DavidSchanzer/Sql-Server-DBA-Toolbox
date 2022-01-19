SET NOCOUNT ON;

DECLARE @print_only BIT = 1,
        @job_id UNIQUEIDENTIFIER,
        @name sysname,
        @command NVARCHAR(MAX),
        @message VARCHAR(1000);

-- Change the SQL Agent job history purge period from 30 days to 90 days in the Ola Hallengren sp_purge_jobhistory job
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
WHERE [name] = 'sp_purge_jobhistory'
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

    IF CHARINDEX(N'DATEADD(dd,-30,GETDATE())', @command) > 0
    BEGIN
        SET @command = REPLACE(@command, N'DATEADD(dd,-30,GETDATE())', N'DATEADD(dd,-90,GETDATE())');

        IF @print_only = 0
        BEGIN
            EXEC [msdb].[dbo].[sp_update_jobstep] @job_id = @job_id,
                                                  @step_id = 1,
                                                  @command = @command;

            SET @message = @name + ':  updated command to ' + @command;
        END;
        ELSE
        BEGIN
            SET @message = @name + ':  would update command to ' + @command;
        END;

        PRINT @message;
    END;

    FETCH [job_cur]
    INTO @job_id,
         @name;
END;

CLOSE [job_cur];
DEALLOCATE [job_cur];
