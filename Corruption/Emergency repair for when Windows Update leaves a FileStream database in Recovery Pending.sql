-- Emergency repair for when Windows Update leaves a FileStream database in Recovery Pending
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script avoids having to perform a database restore in the occasional circumstance where Windows patching
-- causes a database that uses FileStream into the Recovery Pending state.
-- Replace all <DBName> with the relevant database name.

USE [master];
GO
EXEC sp_configure @configname = 'filestream access level', @configvalue = 2;
RECONFIGURE WITH OVERRIDE;
GO
ALTER DATABASE <DBName> SET EMERGENCY;
GO
ALTER DATABASE <DBName> SET SINGLE_USER;
GO
DBCC CHECKDB(<DBName>, REPAIR_ALLOW_DATA_LOSS) WITH ALL_ERRORMSGS;
GO
ALTER DATABASE <DBName> SET MULTI_USER;
GO
