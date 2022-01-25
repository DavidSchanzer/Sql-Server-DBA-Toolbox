-- sp_WhoIsActive extended info
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script calls the SP_WhoIsActive stored procedure, passing the optional parameters that will return the most information

EXEC dbo.sp_WhoIsActive @get_locks = 1,
                        @get_outer_command = 1,
                        @get_full_inner_text = 1,
                        @get_plans = 1,
                        @get_transaction_info = 1,
                        @get_task_info = 2,
                        @get_additional_info = 1,
                        @find_block_leaders = 1,
                        @sort_order = '[cpu] desc';
