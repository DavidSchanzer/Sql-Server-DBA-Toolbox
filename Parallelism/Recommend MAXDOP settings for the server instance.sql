-- Recommend MAXDOP settings for the server instance
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script uses yet another method to try to calculate an appropriate value for MAXDOP
-- From the comments at the bottom of https://dba.stackexchange.com/questions/36522/maxdop-setting-algorithm-for-sql-server

/*************************************************************************
Author          :   Dennis Winter (Thought: Adapted from a script from "Kin Shah")
Purpose         :   Recommend MaxDop settings for the server instance
Tested RDBMS    :   SQL Server 2008R2
**************************************************************************/

DECLARE @hyperthreadingRatio BIT;
DECLARE @logicalCPUs INT;
DECLARE @HTEnabled INT;
DECLARE @physicalCPU INT;
DECLARE @logicalCPUPerNuma INT;
DECLARE @NoOfNUMA INT;
DECLARE @MaxDOP INT;

SELECT @logicalCPUs = cpu_count,                     -- [Logical CPU Count]
       @hyperthreadingRatio = hyperthread_ratio,     --  [Hyperthread Ratio]
       @physicalCPU = cpu_count / hyperthread_ratio, -- [Physical CPU Count]
       @HTEnabled = CASE
                        WHEN cpu_count > hyperthread_ratio THEN
                            1
                        ELSE
                            0
                    END                              -- HTEnabled
FROM sys.dm_os_sys_info
OPTION (RECOMPILE);

SELECT @logicalCPUPerNuma = COUNT(parent_node_id) -- [NumberOfLogicalProcessorsPerNuma]
FROM sys.dm_os_schedulers
WHERE [status] = 'VISIBLE ONLINE'
      AND parent_node_id < 64
GROUP BY parent_node_id
OPTION (RECOMPILE);

SELECT @NoOfNUMA = COUNT(DISTINCT parent_node_id)
FROM sys.dm_os_schedulers -- find NO OF NUMA Nodes 
WHERE [status] = 'VISIBLE ONLINE'
      AND parent_node_id < 64;

IF @NoOfNUMA > 1
   AND @HTEnabled = 0
    SET @MaxDOP = @logicalCPUPerNuma;
ELSE IF @NoOfNUMA > 1
        AND @HTEnabled = 1
    SET @MaxDOP = ROUND(@NoOfNUMA / @physicalCPU * 1.0, 0);
ELSE IF @HTEnabled = 0
    SET @MaxDOP = @logicalCPUs;
ELSE IF @HTEnabled = 1
    SET @MaxDOP = @physicalCPU;

IF @MaxDOP > 10
    SET @MaxDOP = 10;
IF @MaxDOP = 0
    SET @MaxDOP = 1;

PRINT 'logicalCPUs : ' + CONVERT(VARCHAR, @logicalCPUs);
PRINT 'hyperthreadingRatio : ' + CONVERT(VARCHAR, @hyperthreadingRatio);
PRINT 'physicalCPU : ' + CONVERT(VARCHAR, @physicalCPU);
PRINT 'HTEnabled : ' + CONVERT(VARCHAR, @HTEnabled);
PRINT 'logicalCPUPerNuma : ' + CONVERT(VARCHAR, @logicalCPUPerNuma);
PRINT 'NoOfNUMA : ' + CONVERT(VARCHAR, @NoOfNUMA);
PRINT '---------------------------';
PRINT 'MAXDOP setting should be : ' + CONVERT(VARCHAR, @MaxDOP);
