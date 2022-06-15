-- Check that SQL Agent is configured to send Database Mail
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script checks that the SQL Server Agent really is configured to use Database Mail, despite what it shows in the GUI:
EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'UseDatabaseMail'
GO
EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'DatabaseMailProfile'
GO

-- If the returned result is not "1" for UseDatabaseMail and "SQL Administrator" for DatabaseMailProfile, then execute:
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1
GO
EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'UseDatabaseMail', N'REG_DWORD', 1
GO
EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'DatabaseMailProfile', N'REG_SZ', N'SQL Administrator'
GO
