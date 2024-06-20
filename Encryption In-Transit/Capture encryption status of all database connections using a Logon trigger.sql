---- Capture encryption status of all database connections using a Logon trigger
---- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
---- This script creates a Logon trigger that records into table zDBAEncryptionAuditing.dbo.EncryptionAuditing all T-SQL TCP database connections except for certain exclusions.
---- It will only record one row per combination of (LoginName, DBName, HostName, ProgramName, EncryptOption), and also recording the most recent LoginTime, SPID and HostProcessID.
---- This allows you to see, for each program on a host that uses a login to make a connection to a database, when the last time was that both an encrypted and an unencrypted
---- connection was made. This enables you to confidently force encrypted connections only, knowing that the last time each program made an unencrypted connection was some time ago,
---- and that the program now makes encrypted connections.

--USE master
--GO

---- Create the zDBAEncryptionAuditing database, dropping it if it already existed
--IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'zDBAEncryptionAuditing')
--BEGIN
--	ALTER DATABASE zDBAEncryptionAuditing SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
--	DROP DATABASE IF EXISTS zDBAEncryptionAuditing;
--END
--GO
--CREATE DATABASE zDBAEncryptionAuditing;
--GO

---- Turn on RCSI, as without this you can get the error:
---- "Snapshot isolation transaction failed accessing database 'zDBAEncryptionAuditing' because snapshot isolation is not allowed in this database. Use ALTER DATABASE to allow snapshot isolation."
--ALTER DATABASE zDBAEncryptionAuditing SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
--ALTER DATABASE zDBAEncryptionAuditing SET READ_COMMITTED_SNAPSHOT ON;
--ALTER DATABASE zDBAEncryptionAuditing SET ALLOW_SNAPSHOT_ISOLATION ON;
--ALTER DATABASE zDBAEncryptionAuditing SET MULTI_USER;
--GO

--USE zDBAEncryptionAuditing;
--GO

--CREATE TABLE dbo.EncryptionAuditing
--(
--    [LoginName] VARCHAR(128) NOT NULL,
--    [DBName] VARCHAR(128) NOT NULL,
--    [HostName] VARCHAR(128) NOT NULL,
--    [ProgramName] VARCHAR(128) NOT NULL,
--    [EncryptOption] CHAR(5) NOT NULL,
--    [MostRecentLoginTime] VARCHAR(128) NULL,
--    [MostRecentSPID] INT NULL,
--    [MostRecentHostProcessID] INT NULL
--);

---- Create the PK on the combination of columns that we want to be unique, to limit the number of rows in this table
--ALTER TABLE dbo.EncryptionAuditing
--ADD CONSTRAINT PK_EncryptionAuditing
--    PRIMARY KEY CLUSTERED (
--                              LoginName,
--                              DBName,
--                              HostName,
--                              ProgramName,
--                              EncryptOption
--                          );
--GO

--DROP TRIGGER IF EXISTS TR_zDBAEncryptionAuditing
--ON ALL SERVER;
--GO

-- Create the logon trigger
CREATE OR ALTER TRIGGER TR_zDBAEncryptionAuditing
ON ALL SERVER
WITH EXECUTE AS N'sa'
FOR LOGON
AS
DECLARE @EventData XML,
        @SPID INT,
        @EncryptOption NVARCHAR(40),
        @LoginName VARCHAR(256),
        @LoginTime VARCHAR(128),
        @DBName NVARCHAR(128),
        @HostName NVARCHAR(128),
        @ProgramName NVARCHAR(128),
        @HostProcessID INT,
		@NetTransport NVARCHAR(40);

-- Create the table if it doesn't already exist - this is just in case someone drops the table, which might cause all login attempts to fail.
IF NOT EXISTS
(
    SELECT 1
    FROM zDBAEncryptionAuditing.sys.tables
    WHERE name = 'EncryptionAuditing'
)
BEGIN
    CREATE TABLE zDBAEncryptionAuditing.dbo.EncryptionAuditing
    (
        [LoginName] VARCHAR(128) NOT NULL,
        [DBName] VARCHAR(128) NOT NULL,
        [HostName] VARCHAR(128) NOT NULL,
        [ProgramName] VARCHAR(128) NOT NULL,
        [EncryptOption] CHAR(5) NOT NULL,
        [MostRecentLoginTime] VARCHAR(128) NULL,
        [MostRecentSPID] INT NULL,
        [MostRecentHostProcessID] INT NULL
    );

    ALTER TABLE zDBAEncryptionAuditing.dbo.EncryptionAuditing
    ADD CONSTRAINT PK_EncryptionAuditing
        PRIMARY KEY CLUSTERED (
                                  LoginName,
                                  DBName,
                                  HostName,
                                  ProgramName,
                                  EncryptOption
                              );
END;

SET @EventData = EVENTDATA();

SET @LoginName = ISNULL(@EventData.value('(/EVENT_INSTANCE/LoginName)[1]', 'VARCHAR(256)'), '');
SET @LoginTime = @EventData.value('(/EVENT_INSTANCE/PostTime)[1]', 'VARCHAR(128)');
SET @SPID = @EventData.value('(/EVENT_INSTANCE/SPID)[1]', 'INT');

SELECT @DBName = ISNULL(DB_NAME(database_id), ''),
       @HostName = ISNULL(host_name, ''),
       @ProgramName = ISNULL(program_name, ''),
       @HostProcessID = host_process_id
FROM sys.dm_exec_sessions
WHERE session_id = @SPID;

SELECT @EncryptOption = ISNULL(encrypt_option, ''), @NetTransport = net_transport
FROM sys.dm_exec_connections
WHERE session_id = @SPID;

-- Don't bother inserting a row for certain values of ProgramName, LoginName and DBName, as these come from applications that we don't need to track.
IF @NetTransport = 'TCP'
   AND @ProgramName NOT LIKE 'SQLAgent%'
   AND @ProgramName NOT LIKE 'Microsoft SQL Server%'
   AND @ProgramName NOT LIKE 'Red Gate Software%'
   AND @ProgramName NOT LIKE 'SSIS%'
   AND @ProgramName NOT LIKE 'Report Server%'
   AND @ProgramName NOT LIKE '\[TSS%' ESCAPE '\'
   AND @LoginName <> 'NT AUTHORITY\SYSTEM'
   AND @DBName NOT LIKE 'ReportServer%'
BEGIN
	-- Use the MERGE command to insert a row if there's no match on the PK columns, else update the row
    MERGE zDBAEncryptionAuditing.dbo.EncryptionAuditing AS tgt
    USING
    (
        SELECT @LoginName,
               @DBName,
               @HostName,
               @ProgramName,
               @EncryptOption,
               @LoginTime,
               @SPID,
               @HostProcessID
    ) AS src
    (LoginName, DBName, HostName, ProgramName, EncryptOption, MostRecentLoginTime, MostRecentSPID, MostRecentHostProcessID)
    ON (
           tgt.LoginName = src.LoginName
           AND tgt.DBName = src.DBName
           AND tgt.HostName = src.HostName
           AND tgt.ProgramName = src.ProgramName
           AND tgt.EncryptOption = src.EncryptOption
       )
    WHEN MATCHED THEN
        UPDATE SET MostRecentLoginTime = @LoginTime,
                   MostRecentSPID = @SPID,
                   MostRecentHostProcessID = @HostProcessID
    WHEN NOT MATCHED THEN
        INSERT
        (
            LoginName,
            DBName,
            HostName,
            ProgramName,
            EncryptOption,
            MostRecentLoginTime,
            MostRecentSPID,
            MostRecentHostProcessID
        )
        VALUES
        (src.LoginName, src.DBName, src.HostName, src.ProgramName, src.EncryptOption, src.MostRecentLoginTime,
         src.MostRecentSPID, src.MostRecentHostProcessID);
END;
GO
