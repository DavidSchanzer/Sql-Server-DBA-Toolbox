-- SQLSkills index script 3 - sp_SQLskills_finddupes (modified)
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script is the third of 3 indexing scripts from SQL Skills - this one creates stored proc sp_SQLskills_finddupes.
-- It has been modified to also include as a duplicate non-clustered indexes that have the identical columns in the same order as the
-- clustered index.

/*============================================================================
  Summary:  Run against a single database this procedure will list ALL
            duplicate indexes and the needed TSQL to drop them!
					
  Date:     November 2021

  Version:	SQL Server 2005-2019
------------------------------------------------------------------------------
  Written by Kimberly L. Tripp, SYSolutions, Inc.

  For more scripts and sample code, check out 
    http://www.SQLskills.com

============================================================================*/

USE [master];
GO

IF OBJECTPROPERTY(OBJECT_ID('sp_SQLskills_SQL2008_finddupes'), 'IsProcedure') = 1
    DROP PROCEDURE [sp_SQLskills_SQL2008_finddupes];
GO


IF OBJECTPROPERTY(OBJECT_ID('sp_SQLskills_finddupes'), 'IsProcedure') = 1
    DROP PROCEDURE [sp_SQLskills_finddupes];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE PROCEDURE [dbo].[sp_SQLskills_finddupes]
(@ObjName NVARCHAR(776) = NULL -- the table to check for duplicates
-- when NULL it will check ALL tables
)
AS

--  Jul 2011: V1 to find duplicate indexes.

-- See my blog for updates and/or additional information
-- http://www.SQLskills.com/blogs/Kimberly (Kimberly L. Tripp)

SET NOCOUNT ON;

DECLARE @ObjID INT, -- the object id of the table
        @DBName sysname,
        @SchemaName sysname,
        @TableName sysname,
        @ExecStr NVARCHAR(4000);

-- Check to see that the object names are local to the current database.
SELECT @DBName = PARSENAME(@ObjName, 3);

IF @DBName IS NULL
    SELECT @DBName = DB_NAME();
ELSE IF @DBName <> DB_NAME()
BEGIN
    RAISERROR(15250, -1, -1);
    -- select * from sys.messages where message_id = 15250
    RETURN (1);
END;

IF @DBName = N'tempdb'
BEGIN
    RAISERROR('WARNING: This procedure cannot be run against tempdb. Skipping tempdb.', 10, 0);
    RETURN (1);
END;

-- Check to see the the table exists and initialize @ObjID.
SELECT @SchemaName = PARSENAME(@ObjName, 2);

IF @SchemaName IS NULL
    SELECT @SchemaName = SCHEMA_NAME();

-- Check to see the the table exists and initialize @ObjID.
IF @ObjName IS NOT NULL
BEGIN
    SELECT @ObjID = OBJECT_ID(@ObjName);

    IF @ObjID IS NULL
    BEGIN
        RAISERROR(15009, -1, -1, @ObjName, @DBName);
        -- select * from sys.messages where message_id = 15009
        RETURN (1);
    END;
END;


CREATE TABLE #DropIndexes
(
    DatabaseName sysname NOT NULL,
    SchemaName sysname NOT NULL,
    TableName sysname NOT NULL,
    IndexToBeDropped sysname NOT NULL,
    IndexToBeKept sysname NOT NULL,
    DropStatement NVARCHAR(2000) NOT NULL,
    DisableStatement NVARCHAR(2000) NOT NULL
);

CREATE TABLE #FindDupes
(
    index_id INT NOT NULL,
    is_disabled BIT NOT NULL,
    index_name sysname NOT NULL,
    index_description VARCHAR(210) NOT NULL,
    index_keys NVARCHAR(2126) NOT NULL,
    included_columns NVARCHAR(MAX) NULL,
    filter_definition NVARCHAR(MAX) NULL,
    columns_in_tree NVARCHAR(2126) NOT NULL,
    columns_in_leaf NVARCHAR(MAX) NOT NULL
);

IF @ObjName IS NOT NULL
    DECLARE TableCursor CURSOR LOCAL STATIC FOR
    SELECT @SchemaName,
           PARSENAME(@ObjName, 1);
ELSE
    DECLARE TableCursor CURSOR LOCAL STATIC FOR
    SELECT SCHEMA_NAME(uid),
           name
    FROM sys.sysobjects
    WHERE type = 'U'
    ORDER BY SCHEMA_NAME(uid),
             name;

OPEN TableCursor;

FETCH TableCursor
INTO @SchemaName,
     @TableName;

-- For each table, list the add the duplicate indexes and save 
-- the info in a temporary table that we'll print out at the end.

WHILE @@fetch_status >= 0
BEGIN
    TRUNCATE TABLE #FindDupes;

    SELECT @ExecStr
        = N'EXEC sp_SQLskills_helpindex ''' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + N''', 1';

    --SELECT @ExecStr

    INSERT #FindDupes
    (
        index_id,
        is_disabled,
        index_name,
        index_description,
        index_keys,
        included_columns,
        filter_definition,
        columns_in_tree,
        columns_in_leaf
    )
    EXEC (@ExecStr);

    --SELECT * FROM #FindDupes

    INSERT #DropIndexes
    (
        DatabaseName,
        SchemaName,
        TableName,
        IndexToBeDropped,
        IndexToBeKept,
        DropStatement,
        DisableStatement
    )
    SELECT DISTINCT
           @DBName,
           @SchemaName,
           @TableName,
           t1.index_name AS IndexToBeDropped,
           t2.index_name AS IndexToBeKept,
           N'DROP INDEX ' + QUOTENAME(@SchemaName, N']') + N'.' + QUOTENAME(@TableName, N']') + N'.' + t1.index_name,
           N'IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(''' + @SchemaName + N'.' + @TableName
           + ''') AND name=''' + SUBSTRING(t1.index_name, 2, LEN(t1.index_name) - 2) + ''') ALTER INDEX ' + t1.index_name
           + ' ON ' + QUOTENAME(@SchemaName, N']') + N'.' + QUOTENAME(@TableName, N']') + ' DISABLE;'
    FROM #FindDupes AS t1
        JOIN #FindDupes AS t2
            ON t1.columns_in_tree = t2.columns_in_tree
               AND
               (
                   t1.columns_in_leaf = t2.columns_in_leaf
                   OR t2.columns_in_leaf = 'All columns "included" - the leaf level IS the data row.'
               )
               AND ISNULL(t1.filter_definition, 1) = ISNULL(t2.filter_definition, 1)
               AND
               (
                   PATINDEX('%unique%', t1.index_description) = PATINDEX('%unique%', t2.index_description)
                   OR t2.index_description LIKE 'clustered%'
               )
               AND t1.index_id > t2.index_id;

    FETCH TableCursor
    INTO @SchemaName,
         @TableName;
END;

DEALLOCATE TableCursor;

IF
(
    SELECT COUNT(*)FROM #DropIndexes
) = 0
    RAISERROR('Database: %s has NO duplicate indexes.', 10, 0, @DBName);
ELSE
    SELECT *
    FROM #DropIndexes
    ORDER BY SchemaName,
             TableName;

RETURN (0);
GO

EXEC sys.sp_MS_marksystemobject 'sp_SQLskills_finddupes';
GO
