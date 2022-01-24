-- Last instance restart date
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script returns the date and time at which this instance was last started

SELECT	[sqlserver_start_time] AS [LastStartupDate]
FROM	[sys].[dm_os_sys_info]
