-- Update database backup schedules
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script updates the schedule for the Ola Hallengren SQL Agent jobs "DatabaseBackup - USER_DATABASES - FULL" and "DatabaseBackup - USER_DATABASES - DIFF".
-- The full backup will be on a random day of the week at a random time between 7pm and 11pm, and the differential backup will be likewise but daily.

SET NOCOUNT ON;

-- 1. Update the schedule for the Full backup job to a random day of the week and a random time between 7pm and 11pm
DECLARE @schedule_id INT,
        @freq_interval INT,
        @random_time INT,
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
