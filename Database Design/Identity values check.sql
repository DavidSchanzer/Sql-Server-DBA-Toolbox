/*=============================================
  File: SQL_Server_identity_values_check.sql

  Authors: Thomas LaRock, http://thomaslarock.com/contact-me/ 
	    Karen Lopez, http://www.datamodel.com/index.php/category/blog/ 

  Original blog post at http://thomaslarock.com/2015/11/sql-server-identity-values-check

  Summary: 
  
	This script will return the following items:
		1. Schema_Name - The name of the schema for which the identity object belongs
		2. Table_Name - The name of the table for which the identity object belongs
		3. Column_Name - The name of the column for which the identity object belongs
		4. Row_Count - The current number of rows in the table, as found in sys.dm_db_partition_stats
		5. Total_Possible_Inserts - The number of inserts theoretically possible for the chosen identity datatype,
			(i.e., if we had started at the min/max value and incremented by a value of +/- 1)
		6. Inserts_Remaining - The number of inserts remaining given the last value and increment 
		7. Inserts_Possible - The number of total inserts possible given the defined seed and increment
		8. Current_Inserts_Used_Pct - The percentage of inserts used, 
		    calculated based upon Inserts_Remaining and Inserts_Possible (i.e., 1 - (IR/IP))
		9. Date_You_Will_Run_Out - The estimated date you will run out, based upon ONE INSERT PER SECOND and added to GETDATE()
		10. Is_Unique - If the identity column has been defined as unique. Possible values are:
			PK - Uniqueness through primary key definition
			UQ - Uniqueness through a unique constraint definition
			INDEX - Uniqueness through the creation of a unique index (and we filter for indexes with only the identity column)
			NONE - No uniqueness defined
		11. Increment_Value - The current increment value
		12. Last_Value - The last value inserted
		13. Min_Value - The minimum value for the chosen identity datatype
		14. Max_Value - The maximum value for the chosen identity datatype
		15. Seed_Value - The chosen seed value

  REMARKS: 
 
	If an identity column has not been used (i.e., no rows inserted yet) then it will not appear in the result set.
	You can see this in the code below, the section:

	WHERE Last_Value IS NOT NULL

	is where we are filtering for identity columns that have a last known value. 
	
	Also, the script should return one row for each identity value for which uniqueness is being enforced. In other words,
	since it is valid for multiple unique indexes with only the identity column as a member, the script should return
	one row for each. 

  Date: November 30th, 2015

  SQL Server Versions: SQL2008, SQL2008R2, SQL2012, SQL2014

  You may alter this code for your own purposes. You may republish
  altered code as long as you give due credit. 

  THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY
  OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
  LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR
  FITNESS FOR A PARTICULAR PURPOSE.

=============================================*/


/*=============================================
 Drop/create our temp table
=============================================*/
IF EXISTS (SELECT * FROM tempdb.dbo.sysobjects 
	WHERE id = OBJECT_ID(N'tempdb.dbo.#tmp_IdentValues')
	AND type IN (N'U'))
	DROP TABLE #tmp_IdentValues
GO

CREATE TABLE #tmp_IdentValues
	(Schema_Name sysname,
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
	Is_Unique CHAR(5),
	Count tinyint)
GO

/*=============================================
 Insert into #tmp_IdentValues 
=============================================*/
INSERT INTO #tmp_IdentValues
select OBJECT_SCHEMA_NAME(si.object_id), OBJECT_NAME(si.object_id)
	, si.name
	, six.index_id
	, CONVERT(DECIMAL(38,0),si.seed_value)
	, CONVERT(DECIMAL(38,0),si.increment_value)
	, CONVERT(DECIMAL(38,0),si.last_value)
	, TYPE_NAME(si.system_type_id)
	, CASE WHEN TYPE_NAME(si.system_type_id) = 'tinyint' THEN 0
	  WHEN TYPE_NAME(si.system_type_id) = 'smallint' THEN -32768
	  WHEN TYPE_NAME(si.system_type_id) = 'int' THEN -2147483648
	  WHEN TYPE_NAME(si.system_type_id) = 'bigint' THEN -9223372036854775808
	  WHEN TYPE_NAME(si.system_type_id) = 'decimal' THEN -99999999999999999999999999999999999999
	  WHEN TYPE_NAME(si.system_type_id) = 'numeric' THEN -99999999999999999999999999999999999999
	  END
	, CASE WHEN TYPE_NAME(si.system_type_id) = 'tinyint' THEN 255
	  WHEN TYPE_NAME(si.system_type_id) = 'smallint' THEN 32767
	  WHEN TYPE_NAME(si.system_type_id) = 'int' THEN 2147483647
	  WHEN TYPE_NAME(si.system_type_id) = 'bigint' THEN 9223372036854775807
	  WHEN TYPE_NAME(si.system_type_id) = 'decimal' THEN 99999999999999999999999999999999999999
	  WHEN TYPE_NAME(si.system_type_id) = 'numeric' THEN 99999999999999999999999999999999999999
	  END 
	, sp.row_count
	, CASE WHEN kc.type IS NULL THEN --If NULL, then we don't have a key constraint, so check for unique index
			CASE WHEN six.is_unique = 0 THEN 'NONE' --If = 0, then we don't have a unique index 
			ELSE 'INDEX'
			END
	  ELSE kc.type 
	  END AS [uniquiness]
	 , COUNT(*) OVER(PARTITION BY OBJECT_SCHEMA_NAME(si.object_id), OBJECT_NAME(si.object_id), si.name) as [Count]
FROM sys.identity_columns si
INNER JOIN sys.tables st ON si.object_id = st.object_id
LEFT OUTER JOIN sys.indexes six ON si.object_id = six.object_id
LEFT OUTER JOIN sys.index_columns sic ON si.object_id = sic.object_id
	AND six.index_id = sic.index_id
LEFT OUTER JOIN sys.key_constraints kc ON kc.parent_object_id = si.object_id AND kc.unique_index_id = six.index_id
INNER JOIN sys.dm_db_partition_stats sp ON sp.object_id = si.object_id
	AND sp.index_id = six.index_id
WHERE TYPE_NAME(si.system_type_id) NOT IN ( 'decimal', 'numeric' )		-- WHERE clause added by David so that arithmetic overflow does not occur
GROUP BY OBJECT_SCHEMA_NAME(si.object_id), OBJECT_NAME(si.object_id)
	, si.name
	, six.index_id
	, CONVERT(DECIMAL(38,0),si.seed_value)
	, CONVERT(DECIMAL(38,0),si.increment_value)
	, CONVERT(DECIMAL(38,0),si.last_value)
	, TYPE_NAME(si.system_type_id)
	, six.name
	, six.is_unique
	, kc.type
	, sp.row_count 
HAVING COUNT(*) < 2 --we are only interested in unique indexes with one column
order by 1,2

/*=============================================
 Select from #tmp_IdentValues 
=============================================*/
SELECT Schema_Name  
	, Table_Name  
	, Column_Name  
	, Row_Count  
	, FLOOR((Max_Value - Min_Value)/ABS(Increment_Value)) AS [Total_Possible_Inserts] 
	, FLOOR(CASE WHEN (Increment_Value > 0) 
	  THEN (Max_Value-Last_Value)/Increment_Value
	  ELSE (Min_Value-Last_Value)/Increment_Value
	  END) AS [Inserts_Remaining] 
	, FLOOR(CASE WHEN (Increment_Value > 0) 
	  THEN (Max_Value-Seed_Value + 1.0)/Increment_Value
	  ELSE (Min_Value-Seed_Value + 1.0)/Increment_Value
	  END) AS [Inserts_Possible] 
	, CAST(
		CASE WHEN (Increment_Value > 0) 
		THEN (100)*(1.0-(CAST(Max_Value-Last_Value AS FLOAT)/CAST(Max_Value-Seed_Value + 1.0 AS FLOAT)))
		ELSE (100)*(1.0-(CAST(Min_Value-Last_Value AS FLOAT)/CAST(Min_Value-Seed_Value + 1.0 AS FLOAT)))
		END AS DECIMAL(10,8))
		AS [Current_Inserts_Used_Pct]  
	, CASE WHEN (Increment_Value > 0) THEN
				CASE WHEN FLOOR((Max_Value - Last_Value)/Increment_Value) <= 2147483647 
				THEN CONVERT(DATE, DATEADD(ss, FLOOR((Max_Value - Last_Value)/Increment_Value), GETDATE()), 103)
				ELSE '1/1/1900' 
				END
		ELSE 
				CASE WHEN FLOOR((Min_Value - Last_Value)/Increment_Value) <= 2147483647 
				THEN CONVERT(DATE, DATEADD(ss, FLOOR((Min_Value - Last_Value)/Increment_Value), GETDATE()), 103)
				ELSE '1/1/1900' 
				END
		END AS [Date_You_Will_Run_Out]
	, Is_Unique 
	, Increment_Value   
	, Last_Value  
	, Min_Value  
	, Max_Value  
	, Seed_Value
FROM #tmp_IdentValues
WHERE Last_Value IS NOT NULL  --only want to include identity columns that have been used
AND (Is_Unique <> 'NONE' AND INDEX_COL(Schema_Name+'.'+ Table_Name, Index_ID, 1) = Column_Name
	OR
	Count = 1
	) 
GROUP BY Schema_Name, Table_Name, Column_Name, Index_ID, Row_Count, Is_Unique, Increment_Value, Last_Value, Min_Value, Max_Value, Seed_Value 
--ORDER BY Current_Inserts_Used_Pct DESC
