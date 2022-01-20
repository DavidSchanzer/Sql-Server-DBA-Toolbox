-- Failover all Availability Groups
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script executes a manual failover for each Availability Group on the instance
-- ** Run this script on the SECONDARY node **
DECLARE @name sysname,
        @sql VARCHAR(255);

DECLARE ag_cur CURSOR LOCAL FAST_FORWARD FOR
SELECT name
FROM sys.availability_groups
FOR READ ONLY;

OPEN ag_cur;

FETCH ag_cur
INTO @name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = 'ALTER AVAILABILITY GROUP ' + @name + ' FAILOVER';
    EXEC (@sql);
    FETCH ag_cur
    INTO @name;
END;

CLOSE ag_cur;
DEALLOCATE ag_cur;
