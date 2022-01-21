-- Identity values check
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- From https://github.com/SQLRockstar/BlogScripts/blob/master/SQL_Server_identity_values_check.sql

-- file begin --
--
/**-/-- to run outside sp -- add dash after **
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
IF OBJECT_ID('[dbo].[SQL_Server_identity_values_check]') IS NULL
BEGIN -- missing
	PRINT '-- [dbo].[SQL_Server_identity_values_check] -- MISSING, creating stub --';
	EXECUTE ('CREATE PROCEDURE [dbo].[SQL_Server_identity_values_check] (@ShowVersion_Chr_p CHAR(1)) AS RETURN 1;');
END -- missing
GO
-- */

/**-/-- to run outside sp -- add dash after **
ALTER PROCEDURE [dbo].[SQL_Server_identity_values_check] (
@ShowHelp_Chr_p CHAR(1) = 'N'
, @ShowVersion_Chr_p CHAR(1) = 'N'
, @Version_Int_p INT = 20160807
)
AS
	IF @ShowVersion_Chr_p = 'Y'
	BEGIN -- Version
		RETURN @Version_Int_p;
	END -- Version

--*/DECLARE @ShowHelp_Chr_p CHAR(1);/*
--*/DECLARE @Version_Int_p INT;/*

--*/SELECT @ShowHelp_Chr_p = 'N';/*
--*/SELECT @Version_Int_p = 20160807;/*
--*/
BEGIN -- procedure
--*/ -- to run outside sp --
	IF @ShowHelp_Chr_p = 'Y'
	BEGIN -- Help
		PRINT '
-- help begin -- [dbo].[SQL_Server_identity_values_check] --
--
--  Summary:
-- --  Original blog post at http://thomaslarock.com/2015/11/sql-server-identity-values-check
--
-- --	This script will return the following items:
-- --		1. Schema_Name - The name of the schema for which the identity object belongs
-- --		2. Table_Name - The name of the table for which the identity object belongs
-- --		3. Column_Name - The name of the column for which the identity object belongs
-- --		4. Row_Count - The current number of rows in the table, as found in sys.dm_db_partition_stats
-- --		5. Total_Possible_Inserts - The number of inserts theoretically possible for the chosen identity datatype,
-- --			(i.e., if we had started at the min/max value and incremented by a value of +/- 1)
-- --		6. Inserts_Remaining - The number of inserts remaining given the last value and increment
-- --		7. Inserts_Possible - The number of total inserts possible given the defined seed and increment
-- --		8. Current_Inserts_Used_Pct - The percentage of inserts used,
-- --		    calculated based upon Inserts_Remaining and Inserts_Possible (i.e., 1 - (IR/IP))
-- --		9. Date_You_Will_Run_Out - The estimated date you will run out, based upon ONE INSERT PER SECOND and added to GETDATE()
-- --		10. Is_Unique - If the identity column has been defined as unique. Possible values are:
-- --			PK - Uniqueness through primary key definition
-- --			UQ - Uniqueness through a unique constraint definition
-- --			INDEX - Uniqueness through the creation of a unique index (and we filter for indexes with only the identity column)
-- --			NONE - No uniqueness defined
-- --		11. Increment_Value - The current increment value
-- --		12. Last_Value - The last value inserted
-- --		13. Min_Value - The minimum value for the chosen identity datatype
-- --		14. Max_Value - The maximum value for the chosen identity datatype
-- --		15. Seed_Value - The chosen seed value
--
--  REMARKS:
-- --	If an identity column has not been used (i.e., no rows inserted yet) then it will not appear in the result set.
-- --	You can see this in the code below, the section:
-- --
-- --	WHERE Last_Value IS NOT NULL
-- --
-- --	is where we are filtering for identity columns that have a last known value.
-- --
-- --	Also, the script should return one row for each identity value for which uniqueness is being enforced. In other words,
-- --	since it is valid for multiple unique indexes with only the identity column as a member, the script should return
-- --	one row for each.
-- --
-- --  You may alter this code for your own purposes. You may republish
-- --  altered code as long as you give due credit.
-- --
-- --  THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY
-- --  OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
-- --  LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR
-- --  FITNESS FOR A PARTICULAR PURPOSE.
--
-- version:
-- -- ' + CONVERT(VARCHAR(8), @Version_Int_p) + ' --
--
-- change log:
-- -- 20151130 -- Thomas LaRock -- Created -- http://thomaslarock.com/contact-me/
-- -- 20151130 -- Karen Lopez -- Created -- http://www.datamodel.com/index.php/category/blog/
-- -- 20160807 -- RLively -- DECIMAL/NUMERIC MIN/MAX NE 31, GT 31 as FLOAT, GT 37 NULL --
-- -- 20160807 -- RLively -- change move [Current_Inserts_Used_Pct] and [Date_You_Will_Run_Out] left --
-- -- 20160807 -- RLively -- add sys.sequences, transaction isolation level, server_name, database_name, help --
--
-- SET
-- -- (ISO standard) any query that compares a value with a null returns a 0 --
-- -- -- SET ANSI_NULLS ON; --
-- -- double quotation mark is used as part of the SQL Server identifier --
-- -- -- SET QUOTED_IDENTIFIER ON; --
-- -- do not roll back transactions if there is an error --
-- -- -- SET XACT_ABORT OFF; --
--
-- return:
-- -- 0 -- success --
-- -- n -- help/version --
--
-- tables/views:
-- -- CRT DRP ALT TRN SEL UPD INS DEL -- tablename -- (CRUD) usage --
-- -- crt drp         sel     ins     -- #tmp_IdentValues --
-- --                 sel             -- sys.dm_db_partition_stats --
-- --                 sel             -- sys.identity_columns --
-- --                 sel             -- sys.index_columns --
-- --                 sel             -- sys.indexes --
-- --                 sel             -- sys.key_constraints --
-- --                 sel             -- sys.sequences --
-- --                 sel             -- sys.tables --
--
-- dependencies:
-- -- none --
--
-- messages:
-- -- none --
--
-- works with:
-- -- SQL Server 7.0   : no --
-- -- SQL Server 2000  : no --
-- -- SQL Server 2005  : no --
-- -- SQL Server 2008  : no --
-- -- SQL Server 2008r2: no --
-- -- SQL Server 2012  : yes --
-- -- SQL Server 2014  : yes --
-- -- SQL Server 2016  : yes --
-- -- SQL Server Azure : unknown --
--
-- usage:
-- -- [[EXEC]UTE] [SQLchg].[SQL_Server_identity_values_check] --
-- -- [	@ShowHelp_Chr_p = ''N''] -- ''Y''=Show Help, ''N''=do NOT show Help --
-- -- [	,@ShowVersion_Chr_p = ''N''] -- ''Y''=Show Version, ''N''=do NOT show Version --
--
-- example:
/*
USE [msdb];
EXECUTE [dbo].[SQL_Server_identity_values_check]
; -- view identities/sequences
*/
--
-- help end -- [dbo].[SQL_Server_identity_values_check] --
';
	RETURN;
	END -- Help

SET NOCOUNT ON;

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

/*=============================================
 Drop/create our temp table
=============================================*/
IF EXISTS (SELECT * FROM tempdb.dbo.sysobjects
	WHERE id = OBJECT_ID(N'tempdb.dbo.#tmp_IdentValues')
	AND type IN (N'U'))
	DROP TABLE #tmp_IdentValues;

CREATE TABLE #tmp_IdentValues
	([Schema_Name] sysname,
	Table_Name sysname,
	Column_Name sysname,
	Index_ID int,
	Seed_Value DECIMAL(38,0),
	Increment_Value DECIMAL(38,0),
	Last_Value DECIMAL(38,0),
	Data_Type sysname,
	Min_Value DECIMAL(38,0),
	Max_Value DECIMAL(38,0),
	Row_Count bigint,
	Is_Unique CHAR(8),
	[Count] tinyint);

/*=============================================
 Insert into #tmp_IdentValues
=============================================*/
INSERT INTO #tmp_IdentValues
SELECT OBJECT_SCHEMA_NAME(si.[object_id])
	, OBJECT_NAME(si.[object_id])
	, si.[name]
	, six.index_id
	, CONVERT(DECIMAL(38,0),si.seed_value)
	, CONVERT(DECIMAL(38,0),si.increment_value)
	, CONVERT(DECIMAL(38,0),si.last_value)
	, TYPE_NAME(si.system_type_id)
	, CASE WHEN TYPE_NAME(si.system_type_id) = 'tinyint' THEN 0
	  WHEN TYPE_NAME(si.system_type_id) = 'smallint' THEN -32768
	  WHEN TYPE_NAME(si.system_type_id) = 'int' THEN -2147483648
	  WHEN TYPE_NAME(si.system_type_id) = 'bigint' THEN -9223372036854775808
	  WHEN TYPE_NAME(si.system_type_id) IN ('decimal','numeric')
	  THEN -CAST(LEFT('9999999999999999999999999999999999999999',(si.[precision] - si.scale)) AS DECIMAL(38,0))
	  END
	, CASE WHEN TYPE_NAME(si.system_type_id) = 'tinyint' THEN 255
	  WHEN TYPE_NAME(si.system_type_id) = 'smallint' THEN 32767
	  WHEN TYPE_NAME(si.system_type_id) = 'int' THEN 2147483647
	  WHEN TYPE_NAME(si.system_type_id) = 'bigint' THEN 9223372036854775807
	  WHEN TYPE_NAME(si.system_type_id) IN ('decimal','numeric')
	  THEN CAST(LEFT('9999999999999999999999999999999999999999',(si.[precision] - si.scale)) AS DECIMAL(38,0))
	  END
	, sp.row_count
	, CASE WHEN kc.[type] IS NULL THEN --If NULL, then we don't have a key constraint, so check for unique index
			CASE WHEN six.is_unique = 0 THEN 'NONE' --If = 0, then we don't have a unique index
			ELSE 'INDEX'
			END
	  ELSE kc.[type]
	  END AS [uniquiness]
	 , COUNT(*) OVER(PARTITION BY OBJECT_SCHEMA_NAME(si.[object_id]), OBJECT_NAME(si.[object_id]), si.[name]) as [Count]
FROM sys.identity_columns si
INNER JOIN sys.tables st ON si.[object_id] = st.[object_id]
LEFT OUTER JOIN sys.indexes six ON si.[object_id] = six.[object_id]
LEFT OUTER JOIN sys.index_columns sic ON si.[object_id] = sic.[object_id]
	AND six.index_id = sic.index_id
LEFT OUTER JOIN sys.key_constraints kc ON kc.parent_object_id = si.[object_id] AND kc.unique_index_id = six.index_id
INNER JOIN sys.dm_db_partition_stats sp ON sp.[object_id] = si.[object_id]
	AND sp.index_id = six.index_id
GROUP BY OBJECT_SCHEMA_NAME(si.[object_id])
	, OBJECT_NAME(si.[object_id])
	, si.[name]
	, six.index_id
	, CONVERT(DECIMAL(38,0),si.seed_value)
	, CONVERT(DECIMAL(38,0),si.increment_value)
	, CONVERT(DECIMAL(38,0),si.last_value)
	, TYPE_NAME(si.system_type_id)
	, six.[name]
	, six.is_unique
	, kc.[type]
	, sp.row_count
	, si.[precision]
	, si.scale
HAVING COUNT(*) < 2 --we are only interested in unique indexes with one column
ORDER BY 1,2;

INSERT INTO #tmp_IdentValues
SELECT OBJECT_SCHEMA_NAME(si.[object_id])
	, OBJECT_NAME(si.[object_id])
	, si.[name]
	, 1
	, CONVERT(DECIMAL(38,0),si.start_value)
	, CONVERT(DECIMAL(38,0),si.increment)
	, CONVERT(DECIMAL(38,0),si.current_value)
	, TYPE_NAME(si.system_type_id)
	, CASE WHEN TYPE_NAME(si.system_type_id) = 'tinyint' THEN 0
	  WHEN TYPE_NAME(si.system_type_id) = 'smallint' THEN -32768
	  WHEN TYPE_NAME(si.system_type_id) = 'int' THEN -2147483648
	  WHEN TYPE_NAME(si.system_type_id) = 'bigint' THEN -9223372036854775808
	  WHEN TYPE_NAME(si.system_type_id) IN ('decimal','numeric')
	  THEN -CAST(LEFT('9999999999999999999999999999999999999999',(si.[precision] - si.scale)) AS DECIMAL(38,0))
	  END
	, CASE WHEN TYPE_NAME(si.system_type_id) = 'tinyint' THEN 255
	  WHEN TYPE_NAME(si.system_type_id) = 'smallint' THEN 32767
	  WHEN TYPE_NAME(si.system_type_id) = 'int' THEN 2147483647
	  WHEN TYPE_NAME(si.system_type_id) = 'bigint' THEN 9223372036854775807
	  WHEN TYPE_NAME(si.system_type_id) IN ('decimal','numeric')
	  THEN CAST(LEFT('9999999999999999999999999999999999999999',(si.[precision] - si.scale)) AS DECIMAL(38,0))
	  END
	, 0
	, 'SEQUENCE'
	, 1
FROM sys.sequences si
GROUP BY OBJECT_SCHEMA_NAME(si.[object_id])
	, OBJECT_NAME(si.[object_id])
	, si.[name]
	, CONVERT(DECIMAL(38,0),si.start_value)
	, CONVERT(DECIMAL(38,0),si.increment)
	, CONVERT(DECIMAL(38,0),si.current_value)
	, TYPE_NAME(si.system_type_id)
	, si.[precision]
	, si.scale
ORDER BY 1,2;

/*=============================================
 Select from #tmp_IdentValues
=============================================*/
SELECT @@SERVERNAME AS [Server_Name]
	, DB_NAME() AS [Database_Name]
	, [Schema_Name]
	, Table_Name
	, Column_Name
	, Row_Count
 	, CASE
 		WHEN Max_Value > 9999999999999999999999999999999999999 THEN NULL -- too large to divide without error
		ELSE
			CAST(
				CASE WHEN (Increment_Value > 0)
				THEN (100)*(1.0-(CAST(Max_Value-Last_Value AS FLOAT)/CAST(Max_Value-Seed_Value + 1.0 AS FLOAT)))
				ELSE (100)*(1.0-(CAST(Min_Value-Last_Value AS FLOAT)/CAST(Min_Value-Seed_Value + 1.0 AS FLOAT)))
				END AS DECIMAL(10,8))
	END AS [Current_Inserts_Used_Pct]
	, CASE WHEN Max_Value > 9999999999999999999999999999999 THEN '1/1/1900'  -- too large to divide without error
	ELSE
	 CASE WHEN (Increment_Value > 0) THEN
				CASE WHEN FLOOR((Max_Value - Last_Value)/Increment_Value) <= 2147483647
				THEN CONVERT(DATETIME, DATEADD(ss, FLOOR((Max_Value - Last_Value)/Increment_Value), GETDATE()), 103)
				ELSE '1/1/1900'
				END
		ELSE
				CASE WHEN FLOOR((Min_Value - Last_Value)/Increment_Value) <= 2147483647
				THEN CONVERT(DATETIME, DATEADD(ss, FLOOR((Min_Value - Last_Value)/Increment_Value), GETDATE()), 103)
				ELSE '1/1/1900'
				END
		END
		END AS [Date_You_Will_Run_Out]
	, CASE
		WHEN Max_Value > 9999999999999999999999999999999999999 THEN NULL -- too large to divide without error
		WHEN Max_Value > 9999999999999999999999999999999 THEN -- float less exact
			CAST(FLOOR(CAST(Max_Value - Min_Value AS FLOAT)/ABS(Increment_Value)) AS NUMERIC(38,0))
		ELSE
			FLOOR((Max_Value - Min_Value)/ABS(Increment_Value))
	END AS [Total_Possible_Inserts]
	, CASE
		WHEN Max_Value > 9999999999999999999999999999999999999 THEN NULL -- too large to divide without error
		WHEN Max_Value > 9999999999999999999999999999999 THEN -- float less exact
			FLOOR(CASE WHEN (Increment_Value > 0)
				THEN CAST(CAST(Max_Value-Last_Value AS FLOAT)/CAST(Increment_Value AS FLOAT) AS NUMERIC(38,0))
				ELSE CAST(CAST(Min_Value-Last_Value AS FLOAT)/CAST(Increment_Value AS FLOAT) AS NUMERIC(38,0))
			END)
		ELSE
			FLOOR(CASE WHEN (Increment_Value > 0)
				THEN (Max_Value-Last_Value)/Increment_Value
				ELSE (Min_Value-Last_Value)/Increment_Value
			END)
	END AS [Inserts_Remaining]
	, CASE
		WHEN Max_Value > 9999999999999999999999999999999999999 THEN NULL -- too large to divide without error
		WHEN Max_Value > 9999999999999999999999999999999 THEN -- float less exact
			FLOOR(CASE WHEN (Increment_Value > 0)
				THEN CAST((CAST(Max_Value-Seed_Value + 1.0 AS FLOAT))/CAST(Increment_Value AS FLOAT) AS NUMERIC(38,0))
				ELSE CAST((CAST(Min_Value-Seed_Value + 1.0 AS FLOAT))/CAST(Increment_Value AS FLOAT) AS NUMERIC(38,0))
			END)
		ELSE
			FLOOR(CASE WHEN (Increment_Value > 0)
				THEN (Max_Value-Seed_Value + 1.0)/Increment_Value
				ELSE (Min_Value-Seed_Value + 1.0)/Increment_Value
			END)
	END AS [Inserts_Possible]
	, Is_Unique
	, Increment_Value
	, Last_Value
	, Min_Value
	, Max_Value
	, Seed_Value
FROM #tmp_IdentValues
WHERE Last_Value IS NOT NULL  --only want to include identity columns that have been used
AND (Is_Unique <> 'NONE' AND INDEX_COL([Schema_Name]+'.'+ Table_Name, Index_ID, 1) = Column_Name
	OR
	[Count] = 1
	)
GROUP BY [Schema_Name], Table_Name, Column_Name, Index_ID, Row_Count, Is_Unique, Increment_Value, Last_Value, Min_Value, Max_Value, Seed_Value
ORDER BY Current_Inserts_Used_Pct DESC;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
END -- procedure
GO

/**-/-- to run outside sp -- add dash after **
EXECUTE [dbo].[SQL_Server_identity_values_check]
IF OBJECT_ID('[dbo].[SQL_Server_identity_values_check]') IS NOT NULL
BEGIN -- found
	PRINT '-- [dbo].[SQL_Server_identity_values_check] -- FOUND, dropping --';
	EXECUTE ('DROP PROCEDURE [dbo].[SQL_Server_identity_values_check];');
END -- found
-- */
GO
--
-- file end --
