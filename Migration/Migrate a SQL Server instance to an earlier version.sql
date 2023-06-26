-- Migrate a SQL Server instance to an earlier version
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox

-- It is well-known that Microsoft does not provide any easy method to downgrade a SQL Server instance from a later version (eg. 2019) to an earlier version (eg. 2016).
-- However, this is occasionally necessary, and so this file contains a number of scripts that make the job easier.
-- The basic steps are:
--		1. Install a new empty "migrate" instance (called SQL2016_MIGRATE in the scripts below), probably on another server.
--		2. Migrate all instance-level objects (logins, linked servers, agent jobs, etc) from the "later version" instance to the "migrate" instance using dbatools' Start-DbaMigration.
--		3. For every user database, use SSMS' "Generate Scripts" function to generate the SQL to create all database objects, then execute on the "migrate" instance.
--		4. For each user database, disable all non-clustered indexes in the "migrate" instance to make the data loading faster.
--		5. Check whether any user database has a computed column. If it does, you can't just use the method in the next step to copy all data from all tables,
--		   because the tool doesn't take into account that computed columns shouldn't be included. Instead (crazily), you have to drop the computed column on the
--		   table on the "migrate" instance, and then specify a query that excludes the computed column on the "later version" instance.
--		6. If a user database doesn't contain a computed column, you can copy all data from the later instance to the "migrate" instance using dbatools'
--		   "Get-DbaDbTable" and "Copy-DbaDbTableData" commands.
--		7. For each user database, rebuild all non-clustered indexes in the "migrate" instance.
--		8. Use Red Gate SQL Compare to ensure that the schemas are identical for each user database between the later instance and the "migrate" instance.
--		9. Compare row counts of all tables on all databases between the later instance and the "migrate" instance to ensure that all data has been migrated.
--		10. On the server to be downgraded, uninstall the "later version" SQL Server instance and install and configure the "earlier version" using the same instance name.
--		11. Migrate all instance-level objects from the "migrate" instance to the "earlier version" instance using dbatools' Start-DbaMigration.
--		12. Backup and restore the databases from the "migrate" instance to the "earlier version" instance.

-- Starting from Step 2: Migrate all instance-level objects (logins, linked servers, agent jobs, etc) from the later instance to the "migrate" instance using dbatools' Start-DbaMigration.
-- First delete any existing instance-level objects in the "migrate" instance (but don't delete your own login or you'll be locked out of the instance!).
-- Now, run the PowerShell ISE as Administrator, and then run :
--		Import-Module dbatools
--		Start-DbaMigration -Source <SourceInstance> -Destination SVCISQL-P05MDB\SQL2016_MIGRATE -Exclude Databases >MigrateInstance.log

-- Step 3: For every user database, use SSMS' "Generate Scripts" function to generate the SQL to create all database objects, then execute on the "migrate" instance.
-- For each user database, right-click on the database and select Tasks -> Generate Scripts... and select these options:
--		Script for Server Version: 			<older version of SQL Server>
--		Script Collation:					True
--		Script Object-Level Permissions:	True
--		Script Owner: 						True
--		Types of data to script: 			Schema only
--		Table/View Options: 				set all to True
-- Remember to change the path for the data and log files to match the "migrate" instance before you run the script.

-- Step 4: For each user database on the "migrate" instance, disable all non-clustered indexes in the "migrate" instance to make the data loading faster.
-- Script needs to be executed on each user database:
DECLARE @DisableOrRebuild as nvarchar(20), @Sql NVARCHAR(255)
SET @DisableOrRebuild = 'DISABLE'  
--SET @DisableOrRebuild = 'REBUILD' -- Uncomment for REBUILD

DECLARE IndexCur CURSOR LOCAL FAST_FORWARD FOR
	SELECT N'ALTER INDEX ' + quotename(i.name) + N' ON ' + quotename(s.name) + '.' + quotename(o.name) + ' ' + @DisableOrRebuild + N';' + CHAR(13) + CHAR(10)
	  FROM sys.indexes i
	 INNER JOIN sys.objects o ON i.object_id = o.object_id
	 INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
	 WHERE i.type_desc = N'NONCLUSTERED'
	   AND o.type_desc = N'USER_TABLE'
	 ORDER BY s.name, o.name;

OPEN IndexCur;
FETCH IndexCur INTO @Sql;
WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT @Sql;
	--EXEC (@Sql);
	FETCH IndexCur INTO @Sql;
END
CLOSE IndexCur;
DEALLOCATE IndexCur;

-- Step 5: Check whether any user database has a computed column. If it does, you can't just use the method in the next step to copy all data from all tables,
--		   because the tool doesn't take into account that computed columns shouldn't be included. Instead (crazily), you have to drop the computed column on the
--		   table on the "migrate" instance, and then specify a query that excludes the computed column on the "later version" instance.
-- To generate the Powershell commands (in two separate columns) to drop and re-add all computed columns:
SELECT 
  SCHEMA_NAME(t.schema_id) AS SchemaName,
  OBJECT_NAME(cc.object_id) AS TableName,
  cc.name AS ColumnName,
  cc.definition,
  'Invoke-DbaQuery -SqlInstance ' + @@SERVERNAME + ' -Database ' + DB_NAME() + ' -Query ''ALTER TABLE [' + SCHEMA_NAME(t.schema_id) + '].[' + OBJECT_NAME(cc.object_id) + '] DROP COLUMN [' + cc.name + ']''' AS DropColumnStatement,
  'Invoke-DbaQuery -SqlInstance ' + @@SERVERNAME + ' -Database ' + DB_NAME() + ' -Query "ALTER TABLE [' + SCHEMA_NAME(t.schema_id) + '].[' + OBJECT_NAME(cc.object_id) + '] ADD [' + cc.name + '] AS ' + cc.definition + '"' AS AddColumnStatement
FROM sys.computed_columns AS cc
INNER JOIN sys.tables AS t ON cc.object_id = t.object_id
ORDER BY SchemaName, TableName, ColumnName;
-- If it turns out that a database does contain at least one table with a computed column, then execute the PowerShell commands in the "DropColumnStatement" column.
-- Then run this query to generate the Powershell commands to copy each table's data separately:
SELECT SCHEMA_NAME(schema_id) AS SchemaName,
       name AS TableName,
	   'Copy-DbaDbTableData -SqlInstance ' + @@SERVERNAME + ' -Database "' + DB_NAME() + '" -Destination SVCISQL-P05MDB\SQL2016_MIGRATE -Table "[' + SCHEMA_NAME(schema_id) + '].[' + name + ']" -KeepIdentity -KeepNulls | Select-Object DestinationDatabase, DestinationSchema, DestinationTable, RowsCopied, Elapsed | Format-Table -AutoSize' AS CopyCommand
FROM sys.tables
ORDER BY SchemaName,
         TableName;
-- Modify the statements for the tables that contain computed column to add the "-Query" parameter listing all columns except the computed column(s), such as:
--		Copy-DbaDbTableData -SqlInstance SVCIBIS-M01MDB\BIS_REM -Database Application -Destination SVCISQL-P05MDB\SQL2016_MIGRATE -Table "[dbo].[IDN_Identifiers]" -KeepIdentity -KeepNulls -Query "SELECT [identifier], [internalIdentity], [isCurrent], [namespace] FROM [dbo].[IDN_Identifiers]" | Select-Object DestinationDatabase, DestinationSchema, DestinationTable, RowsCopied, Elapsed | Format-Table -AutoSize

-- Step 6. If a user database doesn't contain a computed column, you can copy all data from the later instance to the "migrate" instance using dbatools'
-- "Get-DbaDbTable" and "Copy-DbaDbTableData" commands.
-- Run the PowerShell ISE as Administrator, and then run:
--		Import-Module dbatools
--		Get-DbaDbTable -SqlInstance <SourceInstance> -Database <DatabaseName> | Copy-DbaDbTableData -Destination SVCISQL-P05MDB\SQL2016_MIGRATE -KeepIdentity -KeepNulls -Truncate | Select-Object DestinationDatabase, DestinationTable, RowsCopied, Elapsed

-- Step 7: For each user database, rebuild all non-clustered indexes in the "migrate" instance.
-- Re-run the script at Step 4 above, commenting out the "DISABLE" line and uncommenting the "REBUILD" line, and run it on the "migrate" instance.

-- Step 8. Use Red Gate SQL Compare to ensure that the schemas are identical for each user database between the later instance and the "migrate" instance.

-- Step 9. Compare row counts of all tables on all databases between the later instance and the "migrate" instance to ensure that all data has been migrated.
-- Run the script below on both the "later version" and "migrate" instances, then save the output as a CSV file, and then use DiffMerge to compare the two CSV files
-- to ensure that the row counts are identical.
DROP TABLE IF EXISTS #RowCounts;
CREATE TABLE #RowCounts (DBName sysname, TableName sysname, [RowCount] INT);
INSERT INTO #RowCounts
	EXEC sp_ineachdb 'SELECT DB_NAME(), QUOTENAME(SCHEMA_NAME(sOBJ.schema_id)) + ''.'' + QUOTENAME(sOBJ.name) AS [TableName], SUM(sPTN.rows) AS [RowCount] FROM sys.objects AS sOBJ INNER JOIN sys.partitions AS sPTN ON sOBJ.object_id=sPTN.object_id WHERE sOBJ.type=''U'' AND sOBJ.is_ms_shipped=0x0 AND index_id < 2 GROUP BY sOBJ.schema_id, sOBJ.name;', @user_only = 1, @exclude_list = 'BreastScreening, ReportServer, ReportServerTempDB';
SELECT * FROM #RowCounts ORDER BY DBName, TableName;

-- Step 10. On the server to be downgraded, uninstall the "later version" SQL Server instance, delete all of the data and log files, and then install and configure
-- the "earlier version" using the same instance name.

-- Step 11. Migrate all instance-level objects from the "migrate" instance to the "earlier version" instance using dbatools' Start-DbaMigration.
-- Run the PowerShell ISE as Administrator, and then run :
--		Import-Module dbatools
--		Start-DbaMigration -Source SVCISQL-P05MDB\SQL2016_MIGRATE -Destination <DestinationInstance> -Exclude Databases >MigrateInstance.log

-- Step 12. Backup and restore the databases from the "migrate" instance to the "earlier version" instance.
