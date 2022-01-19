-- From https://www.simple-talk.com/sql/t-sql-programming/checking-the-plan-cache-warnings-for-a-sql-server-database/

-- =============================================
-- Author:           Dennes Torres
-- Create date: 01/23/2015
-- Description:      return the query plans in cache for a specific database
-- =============================================
ALTER FUNCTION [dbo].[planCachefromDatabase]
(     
       -- Add the parameters for the function here
       @DatabaseName varchar(50)
)
RETURNS TABLE
AS
RETURN
(
  with xmlnamespaces
  (default 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
select qp.query_plan,qt.text,
  statement_start_offset, statement_end_offset,
  creation_time, last_execution_time,
  execution_count, total_worker_time,
  last_worker_time, min_worker_time,
  max_worker_time, total_physical_reads,
  last_physical_reads, min_physical_reads,
  max_physical_reads, total_logical_writes,
  last_logical_writes, min_logical_writes,
  max_logical_writes, total_logical_reads,
  last_logical_reads, min_logical_reads,
  max_logical_reads, total_elapsed_time,
  last_elapsed_time, min_elapsed_time,
  max_elapsed_time, total_rows,
  last_rows, min_rows,
  max_rows
from sys.dm_exec_query_stats
  CROSS APPLY sys.dm_exec_sql_text(sql_handle) qt
  CROSS APPLY sys.dm_exec_query_plan(plan_handle) qp
  where qp.query_plan.exist('//ColumnReference[fn:lower-case(@Database)=fn:lower-case(sql:variable("@DatabaseName"))]')=1
)
 
GO

-- =============================================
-- Author:           Dennes Torres
-- Create date: 01/24/2015
-- Description:      Return the warnings in the query plans in cache
-- =============================================
ALTER FUNCTION [dbo].[FindWarnings]
(     
       -- Add the parameters for the function here
       @DatabaseName varchar(50)
)
RETURNS TABLE
AS
RETURN
(
  with xmlnamespaces
    (default 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'),
   qry as
    (select [text],
            cast(nos.query('local-name(.)') as varchar) warning, total_worker_time
       from dbo.planCachefromDatabase(@DatabaseName)
       CROSS APPLY query_plan.nodes('//Warnings/*') (nos)
                                  )
select [text],warning,count(*) qtd,max(total_worker_time) total_worker_time 
  from qry
  group by [text],warning
)
 
GO

select * from dbo.FindWarnings('[papregdb]')
  order by total_worker_time DESC
