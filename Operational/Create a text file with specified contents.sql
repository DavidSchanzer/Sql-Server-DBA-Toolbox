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

IF EXISTS (SELECT * FROM SysObjects WHERE Name = 'usp_WriteToTextFile' ) 
   BEGIN DROP PROC dbo.usp_WriteToTextFile END;
GO

CREATE PROC dbo.usp_WriteToTextFile
        @text        varchar(1000),
        @file        varchar(255),
        @overwrite   bit = 0
AS 
BEGIN
   EXEC sp_configure 'show advanced options', 1;
   RECONFIGURE;
   EXEC sp_configure 'xp_cmdshell', 1;
   RECONFIGURE;

   SET NOCOUNT ON;
   DECLARE @query varchar(255);
   SET @query = 'ECHO ' + coalesce(ltrim(@text),'-')
                 + CASE WHEN (@overwrite = 1) THEN ' > ' ELSE ' >> '
                   END
                 + rtrim(@file);
   EXEC master..xp_cmdshell @query 
 
   SET NOCOUNT OFF;
   EXEC sp_configure 'xp_cmdshell', 0;
   RECONFIGURE;
END;
GO

GRANT EXEC ON dbo.usp_WriteToTextFile TO public;
GO

