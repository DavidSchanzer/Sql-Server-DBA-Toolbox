-- Drop all statistics
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script generates DROP statements for all statistics objects in all databases
-- From https://blogs.msdn.microsoft.com/mvpawardprogram/2013/09/09/sql-server-auto-statistics-cleanup/

USE [master];
GO

SET NOCOUNT ON;

-- Table to hold all auto stats and their DROP statements
CREATE TABLE #commands
(
    Database_Name sysname NOT NULL,
    Table_Name sysname NOT NULL,
    Stats_Name sysname NOT NULL,
    cmd NVARCHAR(4000) NOT NULL,
    CONSTRAINT PK_#commands
        PRIMARY KEY CLUSTERED (
                                  Database_Name,
                                  Table_Name,
                                  Stats_Name
                              )
);

-- A cursor to browse all user databases
DECLARE Databases CURSOR LOCAL FAST_FORWARD FOR
SELECT [name]
FROM sys.databases
WHERE database_id > 4;

DECLARE @Database_Name sysname,
        @cmd NVARCHAR(4000);

OPEN Databases;

FETCH NEXT FROM Databases
INTO @Database_Name;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Create all DROP statements for the database
    SET @cmd
        = N'SELECT N''' + @Database_Name
          + N''',
 so.name,
 ss.name,
 N''DROP STATISTICS [''
 + ssc.name
 +'']''
 +''.[''
 + so.name
 +'']''
 + ''.[''
 + ss.name
 + ''];''
 FROM ['       + @Database_Name + N'].sys.stats AS ss
 INNER JOIN [' + @Database_Name + N'].sys.objects AS so
 ON ss.[object_id] = so.[object_id]
 INNER JOIN [' + @Database_Name
          + N'].sys.schemas AS ssc
 ON so.schema_id = ssc.schema_id
 WHERE ss.auto_created = 1
 AND
 so.is_ms_shipped = 0';
    --SELECT @cmd; -- DEBUG
    -- Execute and store in temp table
    INSERT INTO #commands
    EXECUTE (@cmd);
    -- Next Database
    FETCH NEXT FROM Databases
    INTO @Database_Name;
END;

WITH Ordered_Cmd
AS -- Add an ordering column to the rows to mark database context

(SELECT ROW_NUMBER() OVER (PARTITION BY Database_Name
                           ORDER BY Database_Name,
                                    Table_Name,
                                    Stats_Name
                          ) AS Row_Num,
        *
 FROM #commands)
SELECT CASE
           WHEN Row_Num = 1

    -- Add the USE statement before the first row for the database
    THEN
               REPLICATE(N'-', 50) + NCHAR(10) + NCHAR(13) + N'USE [' + Database_Name + '];' + NCHAR(10) + NCHAR(13)
           ELSE
               ''
       END + cmd
FROM Ordered_Cmd
ORDER BY Database_Name,
         Table_Name,
         Stats_Name;

-- CLEANUP
CLOSE Databases;
DEALLOCATE Databases;
DROP TABLE #commands;
GO
