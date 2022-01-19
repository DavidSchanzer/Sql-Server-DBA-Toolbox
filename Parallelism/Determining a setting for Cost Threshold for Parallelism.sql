-- From http://sqlknowitall.com/determining-a-setting-for-cost-threshold-for-parallelism/
--
-- "So what do I do with these numbers? In my case, I am trying to get “about” 50% of the queries below the threshold and 50% above.
-- This way, I split the amount of queries using parallelism. This is not going to guarantee me the best performance, but I figured 
-- it was the best objective way to come up with a good starting point.
--
-- If all of my statistics are very close, I just set the Cost Threshold for Parallelism equal to about what that number is. 
-- An average of the 3 and round will work. In many of my cases, this was between 25 and 30.
-- IF the numbers are different, i.e. a few very large costs skew the average up but the median and mode are close, then I will use something between the median and mode."

CREATE TABLE #SubtreeCost
(
    StatementSubtreeCost DECIMAL(18, 2)
);

;WITH XMLNAMESPACES
 (
     DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
 )
INSERT INTO #SubtreeCost
SELECT CAST(n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)') AS DECIMAL(18, 2))
FROM sys.dm_exec_cached_plans AS cp
    CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp
    CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS qn(n)
WHERE n.query('.').exist('//RelOp[@PhysicalOp="Parallelism"]') = 1;

SELECT StatementSubtreeCost
FROM #SubtreeCost
ORDER BY 1;

SELECT AVG(StatementSubtreeCost) AS AverageSubtreeCost
FROM #SubtreeCost;

SELECT (
    (
        SELECT TOP 1
               StatementSubtreeCost
        FROM
        (
            SELECT TOP 50 PERCENT
                   StatementSubtreeCost
            FROM #SubtreeCost
            ORDER BY StatementSubtreeCost ASC
        ) AS A
        ORDER BY StatementSubtreeCost DESC
    ) +
    (
        SELECT TOP 1
               StatementSubtreeCost
        FROM
        (
            SELECT TOP 50 PERCENT
                   StatementSubtreeCost
            FROM #SubtreeCost
            ORDER BY StatementSubtreeCost DESC
        ) AS A
        ORDER BY StatementSubtreeCost ASC
    )
       ) / 2 AS MEDIAN;

SELECT TOP 1
       StatementSubtreeCost AS MODE
FROM #SubtreeCost
GROUP BY StatementSubtreeCost
ORDER BY COUNT(1) DESC;

DROP TABLE #SubtreeCost;
