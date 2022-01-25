-- Plan Cache queries - warnings
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists all queries in the Plan Cache that contain a warning.
-- From https://www.simple-talk.com/sql/t-sql-programming/checking-the-plan-cache-warnings-for-a-sql-server-database/

-- =============================================
-- Author:      Dennes Torres
-- Create date: 01/23/2015
-- Description: Return the query plans in cache for a specific database
-- =============================================
CREATE OR ALTER FUNCTION [dbo].[planCachefromDatabase]
(
    -- Add the parameters for the function here
    @DatabaseName VARCHAR(50)
)
RETURNS TABLE
AS
RETURN
(
    WITH XMLNAMESPACES
    (
        DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
    )
    SELECT qp.query_plan,
           qt.text,
           qs.statement_start_offset,
           qs.statement_end_offset,
           qs.creation_time,
           qs.last_execution_time,
           qs.execution_count,
           qs.total_worker_time,
           qs.last_worker_time,
           qs.min_worker_time,
           qs.max_worker_time,
           qs.total_physical_reads,
           qs.last_physical_reads,
           qs.min_physical_reads,
           qs.max_physical_reads,
           qs.total_logical_writes,
           qs.last_logical_writes,
           qs.min_logical_writes,
           qs.max_logical_writes,
           qs.total_logical_reads,
           qs.last_logical_reads,
           qs.min_logical_reads,
           qs.max_logical_reads,
           qs.total_elapsed_time,
           qs.last_elapsed_time,
           qs.min_elapsed_time,
           qs.max_elapsed_time,
           qs.total_rows,
           qs.last_rows,
           qs.min_rows,
           qs.max_rows
    FROM sys.dm_exec_query_stats AS qs
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
        CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
    WHERE qp.query_plan.exist('//ColumnReference[fn:lower-case(@Database)=fn:lower-case(sql:variable("@DatabaseName"))]') = 1
);

GO

-- =============================================
-- Author:           Dennes Torres
-- Create date: 01/24/2015
-- Description:      Return the warnings in the query plans in cache
-- =============================================
CREATE OR ALTER FUNCTION [dbo].[FindWarnings]
(
    -- Add the parameters for the function here
    @DatabaseName VARCHAR(50)
)
RETURNS TABLE
AS
RETURN
(
    WITH XMLNAMESPACES
    (
        DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
    )
    , qry
    AS (SELECT PlanCache.[text],
               CAST(nos.query('local-name(.)') AS VARCHAR) AS warning,
               PlanCache.total_worker_time
        FROM dbo.planCachefromDatabase(@DatabaseName) AS PlanCache
            CROSS APPLY query_plan.nodes('//Warnings/*')(nos) )
    SELECT [text],
           warning,
           COUNT(*) qtd,
           MAX(total_worker_time) total_worker_time
    FROM qry
    GROUP BY [text],
             warning
);

GO

SELECT [text],
       warning,
       qtd,
       total_worker_time
FROM dbo.FindWarnings('[' + DB_NAME() + ']')
ORDER BY total_worker_time DESC;
