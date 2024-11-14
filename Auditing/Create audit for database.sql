-- Create audit for database
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script creates server and database audits for the nominated database
-- Values to be modified before execution:
DECLARE @DBName VARCHAR(100) = '<DatabaseName>';
DECLARE @AuditPath VARCHAR(100) = '<PathToAuditsFolder>' + '\' + @DBName;

DECLARE @createDirSql NVARCHAR(100);

SET @createDirSql = N'EXEC master.sys.xp_create_subdir "' + @AuditPath + N'"';

EXEC sys.sp_executesql @stmt = @createDirSql;

DECLARE @AuditSql NVARCHAR(1000);

SET @AuditSql
    = N'USE master;' + N'CREATE SERVER AUDIT [' + @DBName + N'] ' + N'TO FILE ( FILEPATH = ''' + @AuditPath
      + N''', MAXSIZE = 1GB, MAX_ROLLOVER_FILES = 15, RESERVE_DISK_SPACE = OFF ) WITH ( QUEUE_DELAY = 1000, ON_FAILURE = CONTINUE );'
      + N'ALTER SERVER AUDIT [' + @DBName + N'] WITH (STATE = ON);' + N'USE [' + @DBName + N'];'
      + N'CREATE DATABASE AUDIT SPECIFICATION [' + @DBName + N']' + N'FOR SERVER AUDIT [' + @DBName + N']'
      + N'ADD (SCHEMA_OBJECT_ACCESS_GROUP) WITH (STATE = ON);';

EXEC sys.sp_executesql @stmt = @AuditSql;
GO
