-- From the comments at the bottom of https://dba.stackexchange.com/questions/36522/maxdop-setting-algorithm-for-sql-server:

SELECT [ServerName] = @@SERVERNAME,
       [ComputerName] = SERVERPROPERTY('ComputerNamePhysicalNetBIOS'),
       [LogicalCPUs],
       hyperthread_ratio,
       [PhysicalCPU],
       [HTEnabled],
       LogicalCPUPerNuma,
       [NoOfNUMA],
       [MaxDop_Recommended] = CONVERT(   INT,
                                         CASE
                                             WHEN [MaxDop_RAW] > 10 THEN
                                                 10
                                             ELSE
                                                 [MaxDop_RAW]
                                         END
                                     ),
       [MaxDop_Current] = sc.value,
       [MaxDop_RAW],
       [Number of Cores]
FROM
(
    SELECT [LogicalCPUs],
           hyperthread_ratio,
           [PhysicalCPU],
           [HTEnabled],
           LogicalCPUPerNuma,
           [NoOfNUMA],
           [Number of Cores],
           [MaxDop_RAW] = CASE
                              WHEN [NoOfNUMA] > 1
                                   AND HTEnabled = 0 THEN
                                  LogicalCPUPerNuma
                              WHEN [NoOfNUMA] > 1
                                   AND HTEnabled = 1 THEN
                                  CONVERT(
                                             DECIMAL(9, 4),
                                             [NoOfNUMA] / CONVERT(DECIMAL(9, 4), Res_MAXDOP.PhysicalCPU)
                                             * CONVERT(DECIMAL(9, 4), 1)
                                         )
                              WHEN HTEnabled = 0 THEN
                                  Res_MAXDOP.LogicalCPUs
                              WHEN HTEnabled = 1 THEN
                                  Res_MAXDOP.PhysicalCPU
                          END
    FROM
    (
        SELECT [LogicalCPUs] = osi.cpu_count,
               osi.hyperthread_ratio,
               [PhysicalCPU] = osi.cpu_count / osi.hyperthread_ratio,
               [HTEnabled] = CASE
                                 WHEN osi.cpu_count > osi.hyperthread_ratio THEN
                                     1
                                 ELSE
                                     0
                             END,
               LogicalCPUPerNuma,
               [NoOfNUMA],
               [Number of Cores]
        FROM
        (
            SELECT [NoOfNUMA] = COUNT(Res.parent_node_id),
                   [Number of Cores] = Res.LogicalCPUPerNuma / COUNT(Res.parent_node_id),
                   Res.LogicalCPUPerNuma
            FROM
            (
                SELECT s.parent_node_id,
                       LogicalCPUPerNuma = COUNT(1)
                FROM sys.dm_os_schedulers s
                WHERE s.parent_node_id < 64
                      AND s.status = 'VISIBLE ONLINE'
                GROUP BY s.parent_node_id
            ) Res
            GROUP BY Res.LogicalCPUPerNuma
        ) Res_NUMA
            CROSS APPLY sys.dm_os_sys_info osi
    ) Res_MAXDOP
) Res_Final
    CROSS APPLY sys.sysconfigures sc
WHERE sc.comment = 'maximum degree of parallelism'
OPTION (RECOMPILE);
