-- Create a text file with specified contents
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script create stored proc usp_WriteToTextFile that uses xp_cmdshell to create a text file in any folder to which SQL Server has access.

/* ***************************************************************************** */
/* Procedure usp_WriteToTextFile - Write directly to a text file from SQL        */
/* ***************************************************************************** */
/*                                                                               */
/* PARAMETERS                                                                    */
/*     @Text       VARCHAR(1000)  What you want written to the output file.      */
/*     @File       VARCHAR(255)   Path and file name to which you wish to write. */
/*     @Overwrite  BIT = 0        Overwrite flag (0 = Append / 1 = Overwrite)    */
/*                                                                               */
/* RETURNS: NULL                                                                 */
/*                                                                               */
/* EXAMPLE                                                                       */
/*                                                                               */
/* EXEC dbo.usp_WriteToTextFile                                                  */
/*     'Hello World.',                                                           */
/*     'C:\Temp\logfile.txt',                                                    */
/*     0                                                                         */
/*                                                                               */
/* ***************************************************************************** */

IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'usp_WriteToTextFile')
BEGIN
    DROP PROC dbo.usp_WriteToTextFile;
END;
GO

CREATE PROC dbo.usp_WriteToTextFile
    @text VARCHAR(1000),
    @file VARCHAR(255),
    @overwrite BIT = 0
AS
BEGIN
    EXEC sys.sp_configure 'show advanced options', 1;
    RECONFIGURE;
    EXEC sys.sp_configure 'xp_cmdshell', 1;
    RECONFIGURE;

    SET NOCOUNT ON;
    DECLARE @query VARCHAR(255);
    SET @query = 'ECHO ' + COALESCE(LTRIM(@text), '-') + CASE
                                                             WHEN (@overwrite = 1) THEN
                                                                 ' > '
                                                             ELSE
                                                                 ' >> '
                                                         END + RTRIM(@file);
    EXEC master..xp_cmdshell @query;

    SET NOCOUNT OFF;
    EXEC sys.sp_configure 'xp_cmdshell', 0;
    RECONFIGURE;
END;
GO

GRANT EXEC ON dbo.usp_WriteToTextFile TO PUBLIC;
GO

