-- spa_ShrinkColumnSizes
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script create a stored procedure that queries the data in VARCHAR and INT columns to see if they can be reduced in size:
-- VARCHAR to CHAR if the min(length) = max(length), else VARCHAR(max(length)), and INT to SMALLINT or TINYINT.
-- The output is a series of ALTER TABLE ALTER COLUMN statements.

CREATE OR ALTER PROC dbo.spa_ShrinkColumnSizes
(
    @SchemaName NVARCHAR(40),
    @TableName NVARCHAR(40),
    @PrintOnly BIT = 1,
    @Debug BIT = 0
)
AS
BEGIN
    DECLARE @Table VARCHAR(100) = @SchemaName + N'.' + @TableName;
    DECLARE @ColumnName NVARCHAR(50),
            @ColumnID TINYINT,
            @ColumnType NVARCHAR(10),
            @ColumnLength SMALLINT,
            @SQLStatus SMALLINT,
            @MinColumnLen SMALLINT,
            @MaxColumnLen SMALLINT,
            @SQL NVARCHAR(500),
            @ParmDefinition NVARCHAR(100),
            @NewColumnType NVARCHAR(10),
            @NewColumnDef NVARCHAR(20),
            @Count INT,
            @Nullity VARCHAR(10),
            @MinVal INT,
            @MaxVal INT;

    IF @Debug = 1
        SELECT '@Table = ' + @Table;

    DECLARE ColumnCur CURSOR LOCAL FAST_FORWARD FOR
    SELECT c.name AS ColumnName,
           c.column_id AS ColumnID,
           t.name AS ColumnType,
           c.max_length AS ColumnLength
    FROM sys.columns AS c
        INNER JOIN sys.types AS t
            ON t.system_type_id = c.system_type_id
    WHERE c.object_id = OBJECT_ID(@Table)
          AND t.name IN ( N'varchar', N'int' );

    OPEN ColumnCur;
    IF @@ERROR <> 0
    BEGIN
        RETURN -1;
    END;

    FETCH ColumnCur
    INTO @ColumnName,
         @ColumnID,
         @ColumnType,
         @ColumnLength;

    SET @SQLStatus = @@FETCH_STATUS;

    WHILE @SQLStatus = 0
    BEGIN
        IF @Debug = 1
            SELECT '@ColumnName = ' + @ColumnName + ', @ColumnID = ' + CAST(@ColumnID AS VARCHAR) + ', @ColumnType = '
                   + @ColumnType + ', @ColumnLength = ' + CAST(@ColumnLength AS VARCHAR);

        IF @ColumnType = 'varchar'
        BEGIN
            SET @SQL
                = N'SELECT @MinColumnLen = MIN(LEN(' + @ColumnName + N')), @MaxColumnLen = MAX(LEN(' + @ColumnName
                  + N')) FROM ' + @Table;
            SET @ParmDefinition = N'@MinColumnLen SMALLINT OUTPUT, @MaxColumnLen SMALLINT OUTPUT';

            EXEC sp_executesql @stmt = @SQL,
                               @params = @ParmDefinition,
                               @MinColumnLen = @MinColumnLen OUTPUT,
                               @MaxColumnLen = @MaxColumnLen OUTPUT;

            IF @MinColumnLen = @MaxColumnLen
                SET @NewColumnType = N'CHAR';
            ELSE
                SET @NewColumnType = N'VARCHAR';

            SET @NewColumnDef = @NewColumnType + N'(' + CAST(@MaxColumnLen AS VARCHAR(10)) + N')';
        END;
        ELSE -- int
        BEGIN
            SET @SQL
                = N'SELECT @MinVal = MIN(' + @ColumnName + N'), @MaxVal = MAX(' + @ColumnName + N') FROM ' + @Table;
            SET @ParmDefinition = N'@MinVal INT OUTPUT, @MaxVal INT OUTPUT';

            EXEC sp_executesql @stmt = @SQL,
                               @params = @ParmDefinition,
                               @MinVal = @MinVal OUTPUT,
                               @MaxVal = @MaxVal OUTPUT;

            IF @MinVal >= 0
               AND @MinVal <= 255
               AND @MaxVal > 0
               AND @MaxVal <= 255
                SET @NewColumnType = N'TINYINT';
            ELSE IF @MinVal >= -32768
                    AND @MinVal <= 32767
                    AND @MaxVal > -32768
                    AND @MaxVal <= 32767
                SET @NewColumnType = N'SMALLINT';
            ELSE
                SET @NewColumnType = N'INT';

            SET @NewColumnDef = @NewColumnType;
        END;

        SET @SQL = N'SELECT @Count = COUNT(1) FROM ' + @Table + N' WHERE ' + @ColumnName + N' IS NULL';
        SET @ParmDefinition = N'@Count INT OUTPUT';
        EXEC sp_executesql @stmt = @SQL,
                           @params = @ParmDefinition,
                           @Count = @Count OUTPUT;
        IF @Count > 0
            SET @Nullity = N'NULL';
        ELSE
            SET @Nullity = N'NOT NULL';

        SET @SQL = N'ALTER TABLE ' + @Table + N' ALTER COLUMN ' + @ColumnName + N' ' + @NewColumnDef + N' ' + @Nullity;
        PRINT @SQL;

        IF @PrintOnly = 0
            EXEC (@SQL);

        FETCH ColumnCur
        INTO @ColumnName,
             @ColumnID,
             @ColumnType,
             @ColumnLength;

        SET @SQLStatus = @@FETCH_STATUS;
    END;

    CLOSE ColumnCur;

    DEALLOCATE ColumnCur;
END;
GO

-- Example
EXEC dbo.spa_ShrinkColumnSizes @SchemaName = N'<SchemaName>',
                               @TableName = N'<TableName>',
                               @PrintOnly = 1,
                               @Debug = 0;
GO
