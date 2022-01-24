-- Calculate MAXDOP
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script attempts to calculate a suitable value for MAXDOP based on NUMA memory configuration, using a combination of xp_cmdshell,
-- Powershell and WMI.
-- From: http://dba.stackexchange.com/questions/36522/what-is-a-good-repeatable-way-to-calculate-maxdop-on-sql-server

-- Turn on xp_cmdshell (temporarily)
EXEC sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
EXEC sp_configure 'xp_cmdshell', 1
GO
RECONFIGURE
GO

/* 
   This will recommend a MAXDOP setting appropriate for your machine's NUMA memory
   configuration.  You will need to evaluate this setting in a non-production 
   environment before moving it to production.

   MAXDOP can be configured using:  
   EXEC sp_configure 'max degree of parallelism',X;
   RECONFIGURE

   If this instance is hosting a Sharepoint database, you MUST specify MAXDOP=1 
   (URL wrapped for readability)
   http://blogs.msdn.com/b/rcormier/archive/2012/10/25/
   you-shall-configure-your-maxdop-when-using-sharepoint-2013.aspx

   Biztalk (all versions, including 2010): 
   MAXDOP = 1 is only required on the BizTalk Message Box
   database server(s), and must not be changed; all other servers hosting other 
   BizTalk Server databases may return this value to 0 if set.
   http://support.microsoft.com/kb/899000
*/
SET NOCOUNT ON;

DECLARE @CoreCount int;
SET @CoreCount = 0;
DECLARE @NumaNodes int;

/*  see if xp_cmdshell is enabled, so we can try to use 
    PowerShell to determine the real core count
*/
DECLARE @T TABLE (
    name varchar(255)
    , minimum int
    , maximum int
    , config_value int
    , run_value int
);
INSERT INTO @T 
EXEC sp_configure 'xp_cmdshell';
DECLARE @cmdshellEnabled BIT;
SET @cmdshellEnabled = 0;
SELECT @cmdshellEnabled = 1 
FROM @T
WHERE run_value = 1;
IF @cmdshellEnabled = 1
BEGIN
    CREATE TABLE #cmdshell
    (
        txt VARCHAR(255)
    );
    INSERT INTO #cmdshell (txt)
    EXEC xp_cmdshell 'powershell -OutputFormat Text -NoLogo -Command "& {Get-WmiObject -namespace "root\CIMV2" -class Win32_Processor -Property NumberOfCores} | select NumberOfCores"';
    SELECT @CoreCount = CONVERT(INT, LTRIM(RTRIM(txt)))
    FROM #cmdshell
    WHERE ISNUMERIC(LTRIM(RTRIM(txt)))=1;
    DROP TABLE #cmdshell;
END
IF @CoreCount = 0 
BEGIN
    /* 
        Could not use PowerShell to get the corecount, use SQL Server's 
        unreliable number.  For machines with hyperthreading enabled
        this number is (typically) twice the physical core count.
    */
    SET @CoreCount = (SELECT i.cpu_count from sys.dm_os_sys_info i); 
END

SET @NumaNodes = (
    SELECT MAX(c.memory_node_id) + 1 
    FROM sys.dm_os_memory_clerks c 
    WHERE memory_node_id < 64
    );

DECLARE @ProposedMaxDOP INT, @CurrentMaxDOP SQL_VARIANT;

SELECT @CurrentMaxDOP = value_in_use FROM sys.configurations WHERE name = 'max degree of parallelism'

/* 3/4 of Total Cores in Machine */
SET @ProposedMaxDOP = @CoreCount * 0.75; 

/* if @ProposedMaxDOP is greater than the per NUMA node
    Core Count, set @ProposedMaxDOP = per NUMA node core count
*/
IF @ProposedMaxDOP > (@CoreCount / @NumaNodes) 
    SET @ProposedMaxDOP = (@CoreCount / @NumaNodes) * 0.75;

/*
    Reduce @ProposedMaxDOP to an even number 
*/
SET @ProposedMaxDOP = @ProposedMaxDOP - (@ProposedMaxDOP % 2);

/* Cap MAXDOP at 8, according to Microsoft */
IF @ProposedMaxDOP > 8 SET @ProposedMaxDOP = 8;

SELECT 'Core count = ' + CAST(@CoreCount AS VARCHAR(MAX)) + ', NUMA nodes = ' + CAST(@NumaNodes AS VARCHAR(MAX)) + ', suggested MAXDOP = ' + CAST(@ProposedMaxDOP as varchar(max)) + ', current MAXDOP = ' + CAST(@CurrentMaxDOP AS VARCHAR);
GO

-- Turn off xp_cmdshell
EXEC sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
EXEC sp_configure 'xp_cmdshell', 0
GO
RECONFIGURE
GO

/*
EXEC sp_configure 'max degree of parallelism', 2;
GO
RECONFIGURE
GO
*/
