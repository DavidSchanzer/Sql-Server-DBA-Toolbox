/*============================================================================
  File:     sp_SQLskills_finddupes - modified by David.sql

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
(
    @ObjName NVARCHAR(776) = NULL		-- the table to check for duplicates
                                        -- when NULL it will check ALL tables
)
AS

--  Jul 2011: V1 to find duplicate indexes.

-- See my blog for updates and/or additional information
-- http://www.SQLskills.com/blogs/Kimberly (Kimberly L. Tripp)

SET NOCOUNT ON;

DECLARE @ObjID INT,			-- the object id of the table
		@DBName	sysname,
		@SchemaName sysname,
		@TableName sysname,
		@ExecStr NVARCHAR(4000);

-- Check to see that the object names are local to the current database.
SELECT @DBName = PARSENAME(@ObjName,3);

IF @DBName IS NULL
    SELECT @DBName = DB_NAME();
ELSE 
IF @DBName <> DB_NAME()
    BEGIN
	    RAISERROR(15250,-1,-1);
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
        RAISERROR(15009,-1,-1,@ObjName,@DBName);
        -- select * from sys.messages where message_id = 15009
        RETURN (1);
    END;
END;


CREATE TABLE #DropIndexes
(
    DatabaseName		sysname,
    SchemaName			sysname,
    TableName			sysname,
    IndexToBeDropped	sysname,
    IndexToBeKept		sysname,
    DropStatement		NVARCHAR(2000),
	DisableStatement	NVARCHAR(2000)--,
	--IndexID1		INT,
	--IndexID2		INT
);

CREATE TABLE #FindDupes
(
    index_id INT,
	is_disabled BIT,
	index_name sysname,
	index_description VARCHAR(210),
	index_keys NVARCHAR(2126),
    included_columns NVARCHAR(MAX),
	filter_definition NVARCHAR(MAX),
	columns_in_tree NVARCHAR(2126),
	columns_in_leaf NVARCHAR(MAX)
);

-- OPEN CURSOR OVER TABLE(S)
IF @ObjName IS NOT NULL
    DECLARE TableCursor CURSOR LOCAL STATIC FOR
        SELECT @SchemaName, PARSENAME(@ObjName, 1);
ELSE
    DECLARE TableCursor CURSOR LOCAL STATIC FOR 		    
        SELECT SCHEMA_NAME(uid), name 
        FROM sysobjects 
        WHERE type = 'U' --AND name = 'FACT_ASSESSMENT_MDT_REVIEW'
        ORDER BY SCHEMA_NAME(uid), name;
	    
OPEN TableCursor; 

FETCH TableCursor
    INTO @SchemaName, @TableName;

-- For each table, list the add the duplicate indexes and save 
-- the info in a temporary table that we'll print out at the end.

WHILE @@fetch_status >= 0
BEGIN
    TRUNCATE TABLE #FindDupes;
    
    SELECT @ExecStr = 'EXEC sp_SQLskills_helpindex ''' 
                        + QUOTENAME(@SchemaName) 
                        + N'.' 
                        + QUOTENAME(@TableName)
                        + N''', 1';

    --SELECT @ExecStr

    INSERT #FindDupes
    EXEC (@ExecStr);	
    
    --SELECT * FROM #FindDupes
	
    INSERT #DropIndexes
    SELECT DISTINCT @DBName,
            @SchemaName, 
            @TableName, 
            t1.index_name AS IndexToBeDropped,
			t2.index_name AS IndexToBeKept,
            N'DROP INDEX ' 
                + QUOTENAME(@SchemaName, N']') 
                + N'.' 
                + QUOTENAME(@TableName, N']') 
                + N'.' 
                + t1.index_name,
			N'IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('''
				+ @SchemaName
				+ N'.' 
				+ @TableName
				+ ''') AND name=''' 
				+ SUBSTRING(t1.index_name, 2, LEN(t1.index_name) - 2)
				+ ''') ALTER INDEX ' 
				+ t1.index_name 
				+ ' ON ' 
				+ QUOTENAME(@SchemaName, N']') 
				+ N'.' 
				+ QUOTENAME(@TableName, N']') 
				+ ' DISABLE;'--,
			--t1.index_id,
			--t2.index_id
    FROM #FindDupes AS t1
        JOIN #FindDupes AS t2
            ON t1.columns_in_tree = t2.columns_in_tree
                AND ( t1.columns_in_leaf = t2.columns_in_leaf OR t2.columns_in_leaf = 'All columns "included" - the leaf level IS the data row.' )
                AND ISNULL(t1.filter_definition, 1) = ISNULL(t2.filter_definition, 1)
                AND ( PATINDEX('%unique%', t1.index_description) = PATINDEX('%unique%', t2.index_description) OR t2.index_description LIKE 'clustered%' )
                AND t1.index_id > t2.index_id;
                
    FETCH TableCursor
        INTO @SchemaName, @TableName;
END;
	
DEALLOCATE TableCursor;

-- DISPLAY THE RESULTS

IF (SELECT COUNT(*) FROM #DropIndexes) = 0
	    RAISERROR('Database: %s has NO duplicate indexes.', 10, 0, @DBName);
ELSE
    SELECT * FROM #DropIndexes
    ORDER BY SchemaName, TableName;

RETURN (0); -- sp_SQLskills_finddupes
GO

EXEC sys.sp_MS_marksystemobject 'sp_SQLskills_finddupes';
GO