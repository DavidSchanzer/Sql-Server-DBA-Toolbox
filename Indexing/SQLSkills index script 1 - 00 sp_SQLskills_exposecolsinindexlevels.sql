/*============================================================================
  File:     sp_SQLskills_ExposeColsInIndexLevels.sql

  Summary:  This procedure is UPDATED to have a new parameter @IncludeListSorted

  		Consolidated the scripts and added an optional ordering for the
		include to more easily determine duplicates.
  
  Date:     November 2021
  Version:	SQL Server 2008-2019
------------------------------------------------------------------------------
  Written by Kimberly L. Tripp, SQLskills.com

  For more scripts and sample code, check out 
    http://www.SQLskills.com

============================================================================*/

USE master;
GO

IF OBJECTPROPERTY(OBJECT_ID('sp_SQLskills_ExposeColsInIndexLevels_INCLUDE_UNORDERED'), 'IsProcedure') = 1
	DROP PROCEDURE [sp_SQLskills_ExposeColsInIndexLevels_INCLUDE_UNORDERED];

IF OBJECTPROPERTY(OBJECT_ID('sp_SQLskills_ExposeColsInIndexLevels'), 'IsProcedure') = 1
	DROP PROCEDURE [sp_SQLskills_ExposeColsInIndexLevels];
GO

CREATE PROCEDURE [sp_SQLskills_ExposeColsInIndexLevels] 
(
	@object_id INT,
	@index_id INT,
	@ColsInTree NVARCHAR(2126) OUTPUT,
	@ColsInLeaf NVARCHAR(MAX) OUTPUT,
	@IncludeListSorted BIT = 0
)
AS
BEGIN
	DECLARE @nonclus_uniq INT
			, @column_id INT
			, @column_name NVARCHAR(260)
			, @col_descending BIT
			, @colstr	NVARCHAR (MAX);

	-- Get clustered index keys (id and name)
	SELECT sic.column_id, QUOTENAME(sc.name, N']') AS column_name, is_descending_key
	INTO #clus_keys 
	FROM sys.index_columns AS sic
		JOIN sys.columns AS sc
			ON sic.column_id = sc.column_id AND sc.object_id = sic.object_id
	WHERE sic.[object_id] = @object_id
	AND [index_id] = 1;
	
	-- Get nonclustered index keys
	SELECT sic.column_id, sic.is_included_column, QUOTENAME(sc.name, N']') AS column_name, is_descending_key
	INTO #nonclus_keys 
	FROM sys.index_columns AS sic
		JOIN sys.columns AS sc
			ON sic.column_id = sc.column_id 
				AND sc.object_id = sic.object_id
	WHERE sic.[object_id] = @object_id
		AND sic.[index_id] = @index_id;
		
	-- Is the nonclustered unique?
	SELECT @nonclus_uniq = is_unique 
	FROM sys.indexes
	WHERE [object_id] = @object_id
		AND [index_id] = @index_id;

	IF (@nonclus_uniq = 0)
	BEGIN
		-- Case 1: nonunique nonclustered index

		-- cursor for nonclus columns not included and
		-- nonclus columns included but also clus keys
		DECLARE mycursor CURSOR FOR
			SELECT column_id, column_name, is_descending_key  
			FROM #nonclus_keys
			WHERE is_included_column = 0;
		OPEN mycursor;
		FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending;
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT @colstr = ISNULL(@colstr, N'') + @column_name + CASE WHEN @col_descending = 1 THEN '(-)' ELSE N'' END + N', ';
			FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending;
		END;
		CLOSE mycursor;
		DEALLOCATE mycursor;
		
		-- cursor over clus_keys if clustered
		DECLARE mycursor CURSOR FOR
			SELECT column_id, column_name, is_descending_key FROM #clus_keys
			WHERE column_id NOT IN (SELECT column_id FROM #nonclus_keys
				WHERE is_included_column = 0);
		OPEN mycursor;
		FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending;
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT @colstr = ISNULL(@colstr, N'') + @column_name + CASE WHEN @col_descending = 1 THEN '(-)' ELSE N'' END + N', ';
			FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending;
		END;
		CLOSE mycursor;
		DEALLOCATE mycursor;	
		
		SELECT @ColsInTree = SUBSTRING(@colstr, 1, LEN(@colstr) -1);
			
		-- find columns not in the nc and not in cl - that are still left to be included.
		IF @IncludeListSorted = 1
			DECLARE mycursor CURSOR FOR
				SELECT column_id, column_name, is_descending_key FROM #nonclus_keys
				WHERE column_id NOT IN (SELECT column_id FROM #clus_keys UNION SELECT column_id FROM #nonclus_keys WHERE is_included_column = 0)
				ORDER BY column_name
		ELSE
			DECLARE mycursor CURSOR FOR
				SELECT column_id, column_name, is_descending_key FROM #nonclus_keys
				WHERE column_id NOT IN (SELECT column_id FROM #clus_keys UNION SELECT column_id FROM #nonclus_keys WHERE is_included_column = 0)		;
		OPEN mycursor;
		FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending;
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT @colstr = ISNULL(@colstr, N'') + @column_name + CASE WHEN @col_descending = 1 THEN '(-)' ELSE N'' END + N', ';
			FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending;
		END;
		CLOSE mycursor;
		DEALLOCATE mycursor;	
		
		SELECT @ColsInLeaf = SUBSTRING(@colstr, 1, LEN(@colstr) -1);
		
	END;

	-- Case 2: unique nonclustered
	ELSE
	BEGIN
		-- cursor over nonclus_keys that are not includes
		SELECT @colstr = '';
		DECLARE mycursor CURSOR FOR
			SELECT column_id, column_name, is_descending_key FROM #nonclus_keys
			WHERE is_included_column = 0;
		OPEN mycursor;
		FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending;
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT @colstr = ISNULL(@colstr, N'') + @column_name + CASE WHEN @col_descending = 1 THEN '(-)' ELSE N'' END + N', ';
			FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending;
		END;
		CLOSE mycursor;
		DEALLOCATE mycursor;
		
		SELECT @ColsInTree = SUBSTRING(@colstr, 1, LEN(@colstr) -1);
	
		-- start with the @ColsInTree and add remaining columns not present...
		DECLARE mycursor CURSOR FOR
			SELECT column_id, column_name, is_descending_key FROM #nonclus_keys 
			WHERE is_included_column = 1;
		OPEN mycursor;
		FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending;
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT @colstr = ISNULL(@colstr, N'') + @column_name + CASE WHEN @col_descending = 1 THEN '(-)' ELSE N'' END + N', ';
			FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending;
		END;
		CLOSE mycursor;
		DEALLOCATE mycursor;

		-- get remaining clustered column as long as they're not already in the nonclustered
		IF @IncludeListSorted = 1
			DECLARE mycursor CURSOR FOR
				SELECT column_id, column_name, is_descending_key FROM #clus_keys
				WHERE column_id NOT IN (SELECT column_id FROM #nonclus_keys)
				ORDER BY column_name;
		ELSE
			DECLARE mycursor CURSOR FOR
			SELECT column_id, column_name, is_descending_key FROM #clus_keys
			WHERE column_id NOT IN (SELECT column_id FROM #nonclus_keys);
		OPEN mycursor;
		FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending;
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT @colstr = ISNULL(@colstr, N'') + @column_name + CASE WHEN @col_descending = 1 THEN '(-)' ELSE N'' END + N', ';
			FETCH NEXT FROM mycursor INTO @column_id, @column_name, @col_descending;
		END;
		CLOSE mycursor;
		DEALLOCATE mycursor;	

		SELECT @ColsInLeaf = SUBSTRING(@colstr, 1, LEN(@colstr) -1);
		SELECT @colstr = '';
	
	END;
	-- Cleanup
	DROP TABLE #clus_keys;
	DROP TABLE #nonclus_keys;
	
END;
GO

EXEC sys.sp_MS_marksystemobject 'sp_SQLskills_ExposeColsInIndexLevels';
GO
