-- C:\GitHub\Sql Server DBA Toolbox\Agent Jobs\Randomise start times for a SQL Agent job schedule to be within an hour of a given time
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script randomly adds between 0 and 60 minutes to a given SQL Agent job schedule, to avoid the job runnning at exactly the same time on every instance.

USE msdb
GO

DECLARE @schedule_name			sysname = 'Populate Security Audit schedule',
		@job_curr_start_hour	INT = 3,
		@job_curr_start_minute	INT = 30,
		@random_offset_minutes	INT = 60,
		@random_time			DATETIME,
		@random_time_char5		CHAR(5),
		@new_start_time			CHAR(6),
		@print_string			VARCHAR(255)

SET @random_time = DATEADD(MINUTE, RAND() * @random_offset_minutes, DATETIMEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), DAY(GETDATE()), @job_curr_start_hour, @job_curr_start_minute, 0, 0))	-- Add between 0 and 60 minutes to 3:30am today
SET @random_time_char5 = CONVERT(CHAR(5), @random_time, 114)							-- Convert to HH:MM format
SET @new_start_time = LEFT(@random_time_char5, 2) + RIGHT(@random_time_char5, 2) + '00'	-- Convert to HHMMSS format

EXEC dbo.sp_update_schedule @name = @schedule_name,
                                 @active_start_time = @new_start_time;
SET @print_string = 'Updating ' + @schedule_name + ' to ' + @new_start_time
PRINT @print_string
GO
