-- Baseline
DROP TABLE ##TempSpinlockStats1;
GO
SELECT * INTO ##TempSpinlockStats1 FROM sys.dm_os_spinlock_stats
WHERE [collisions] > 0
ORDER BY [name];
GO

-- Do some stuff
WAITFOR DELAY '00:00:05';
GO

-- Capture updated stats
DROP TABLE ##TempSpinlockStats2;
GO
SELECT * INTO ##TempSpinlockStats2 FROM sys.dm_os_spinlock_stats
WHERE [collisions] > 0
ORDER BY [name];
GO

-- Diff them
SELECT
    '***' AS [New],
    ts2.[name] AS [Spinlock],
    ts2.[collisions] AS [DiffCollisions],
    ts2.[spins] AS [DiffSpins],
    ts2.[spins_per_collision] AS [SpinsPerCollision],
    ts2.[sleep_time] AS [DiffSleepTime],
    ts2.[backoffs] AS [DiffBackoffs]
FROM ##TempSpinlockStats2 ts2
LEFT OUTER JOIN ##TempSpinlockStats1 ts1
    ON ts2.[name] = ts1.[name]
WHERE ts1.[name] IS NULL
UNION
SELECT
    '' AS [New],
    ts2.[name] AS [Spinlock],
    ts2.[collisions] - ts1.[collisions] AS [DiffCollisions],
    ts2.[spins] - ts1.[spins] AS [DiffSpins],
    CASE (ts2.[spins] - ts1.[spins]) WHEN 0 THEN 0
        ELSE (ts2.[spins] - ts1.[spins]) / -- > 0 spins = > 0 collisions
        (ts2.[collisions] - ts1.[collisions]) END AS [SpinsPerCollision],
    ts2.[sleep_time] - ts1.[sleep_time] AS [DiffSleepTime],
    ts2.[backoffs] - ts1.[backoffs] AS [DiffBackoffs]
    --, ts2.*
FROM ##TempSpinlockStats2 ts2
LEFT OUTER JOIN ##TempSpinlockStats1 ts1
    ON ts2.[name] = ts1.[name]
WHERE ts1.[name] IS NOT NULL
    AND ts2.[collisions] - ts1.[collisions] > 0
ORDER BY [New] DESC, [Spinlock] ASC;
GO
