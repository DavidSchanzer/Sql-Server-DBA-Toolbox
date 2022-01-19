-- From https://www.sqlskills.com/blogs/erin/why-you-need-query-store-part-iii-proactively-analyze-your-workload/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO

DECLARE @IndexName AS NVARCHAR(128) = N'[PK_Analytics_WeekHits]';
-- Make sure the name passed is appropriately quoted

IF (LEFT(@IndexName, 1) <> '[' AND RIGHT(@IndexName, 1) <> ']')
    SET @IndexName = QUOTENAME(@IndexName);
--Handle the case where the left or right was quoted manually but not the opposite side
IF LEFT(@IndexName, 1) <> '['
    SET @IndexName = N'[' + @IndexName;
IF RIGHT(@IndexName, 1) <> ']'
    SET @IndexName = @IndexName + N']';
WITH XMLNAMESPACES
     (
         DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
     )
SELECT stmt.value('(@StatementText)[1]', 'varchar(max)') AS SQL_Text,
       obj.value('(@Database)[1]', 'varchar(128)') AS DatabaseName,
       obj.value('(@Schema)[1]', 'varchar(128)') AS SchemaName,
       obj.value('(@Table)[1]', 'varchar(128)') AS TableName,
       obj.value('(@Index)[1]', 'varchar(128)') AS IndexName,
       obj.value('(@IndexKind)[1]', 'varchar(128)') AS IndexKind,
       tab.query_plan
FROM
(
    SELECT tp.query_plan
    FROM
    (
        SELECT TRY_CONVERT(XML, qsp.query_plan) AS query_plan
        FROM sys.query_store_plan AS qsp
    ) AS tp
) AS tab(query_plan)
    CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS batch(stmt)
    CROSS APPLY stmt.nodes('.//IndexScan/Object[@Index=sql:variable("@IndexName")]') AS idx(obj)
OPTION (MAXDOP 1, RECOMPILE);
