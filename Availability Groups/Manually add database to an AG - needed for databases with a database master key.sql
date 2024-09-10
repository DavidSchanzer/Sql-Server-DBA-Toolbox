-- Manually add database to an AG - needed for databases with a database master key
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script, which must be run in SQLCMD mode, will use the backup-and-restore method of initialising the secondary node
-- Make the appropriate global replacements of <AGName>, <PrimaryNode>, <SecondaryNode>, <DBName>, <FullBackupPath> and <LogBackupPath>

:CONNECT <PrimaryNode>
ALTER AVAILABILITY GROUP <AGName>
ADD DATABASE <DBName>;
GO
BACKUP DATABASE <DBName>
TO DISK = '<FullBackupPath>'
WITH INIT, FORMAT, STATS = 5;
GO
:CONNECT <SecondaryNode>
RESTORE DATABASE <DBName>
FROM DISK = '<FullBackupPath>'
WITH NORECOVERY, STATS = 5;
GO
:CONNECT <PrimaryNode>
BACKUP LOG <DBName> TO DISK = '<LogBackupPath>'
WITH INIT, FORMAT;
GO
:CONNECT <SecondaryNode>
RESTORE LOG <DBName>
FROM DISK = '<LogBackupPath>'
WITH NORECOVERY;
GO
ALTER DATABASE <DBName> SET HADR AVAILABILITY GROUP = <AGName>;
GO
