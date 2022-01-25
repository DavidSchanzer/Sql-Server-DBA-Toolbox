-- sp_WhoIsActive in a loop
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script calls the SP_WhoIsActive stored procedure 10 times in a loop with a 5-sec delay, storing the result set in a temp table
-- and then displaying the results in descending order of collection time.

DECLARE @destination_table VARCHAR(4000);

SET @destination_table = 'tempdb.dbo.WhoIsActive_'
    + CONVERT(VARCHAR, GETDATE(), 112);

DECLARE @schema VARCHAR(4000);

EXEC dbo.sp_WhoIsActive @get_transaction_info = 1, @get_plans = 1,
    @return_schema = 1, @schema = @schema OUTPUT;

SET @schema = REPLACE(@schema, '<table_name>', @destination_table);

PRINT @schema;

EXEC(@schema);
GO

DECLARE @destination_table VARCHAR(4000),
    @msg NVARCHAR(1000);

SET @destination_table = 'tempdb.dbo.WhoIsActive_'
    + CONVERT(VARCHAR, GETDATE(), 112);

DECLARE @numberOfRuns INT;
SET @numberOfRuns = 10;

WHILE @numberOfRuns > 0
BEGIN;
    EXEC dbo.sp_WhoIsActive @get_transaction_info = 1, @get_plans = 1,
        @destination_table = @destination_table;

    SET @numberOfRuns = @numberOfRuns - 1;

    IF @numberOfRuns > 0
    BEGIN
        SET @msg = CONVERT(CHAR(19), GETDATE(), 121) + ': '
            + 'Logged info. Waiting...';
        RAISERROR(@msg,0,0) WITH NOWAIT;

        WAITFOR DELAY '00:00:05';
    END;
    ELSE
    BEGIN
        SET @msg = CONVERT(CHAR(19), GETDATE(), 121) + ': ' + 'Done.';
        RAISERROR(@msg,0,0) WITH NOWAIT;
    END;

END;
GO

DECLARE @destination_table NVARCHAR(2000),
    @dSQL NVARCHAR(4000);

SET @destination_table = 'tempdb.dbo.WhoIsActive_'
    + CONVERT(VARCHAR, GETDATE(), 112);

SET @dSQL = N'SELECT collection_time, * FROM '
    + @destination_table + N' order by 1 desc';

PRINT @dSQL;

EXEC sys.sp_executesql @dSQL;

SET @dSQL = N'DROP TABLE ' + @destination_table;

PRINT @dSQL;

EXEC sys.sp_executesql @dSQL;
GO
