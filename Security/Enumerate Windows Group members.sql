--###############################################################################################
-- Quick script to enumerate Active directory users who get permissions from An Active Directory Group
--###############################################################################################

--a table variable capturing any errors in the try...catch below
DECLARE @ErrorRecap TABLE
  (
     ID           INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
     AccountName  NVARCHAR(256),
     ErrorMessage NVARCHAR(256)
  ) 

IF OBJECT_ID('tempdb.dbo.#tmp') IS NOT NULL
  DROP TABLE #tmp
--table for capturing valid resutls form xp_logininfo
CREATE TABLE [dbo].[#TMP] ( 
[ACCOUNT NAME]       NVARCHAR(256)                        NULL ,
[TYPE]               VARCHAR(8)                           NULL ,
[PRIVILEGE]          VARCHAR(8)                           NULL ,
[MAPPED LOGIN NAME]  NVARCHAR(256)                        NULL ,
[PERMISSION PATH]    NVARCHAR(256)                        NULL )

 DECLARE @groupname NVARCHAR(256)
 DECLARE c1 cursor LOCAL FORWARD_ONLY STATIC READ_ONLY for
  --###############################################################################################
  --cursor definition
  --###############################################################################################
   SELECT name 
   FROM master.sys.server_principals 
   WHERE type_desc =  'WINDOWS_GROUP' 
   --###############################################################################################
  OPEN c1
  FETCH NEXT FROM c1 INTO @groupname
  WHILE @@FETCH_STATUS <> -1
    BEGIN
      BEGIN TRY
        INSERT INTO #tmp([ACCOUNT NAME],[TYPE],[PRIVILEGE],[MAPPED LOGIN NAME],[PERMISSION PATH])
          EXEC master..xp_logininfo @acctname = @groupname,@option = 'members'     -- show group members
      END TRY
      BEGIN CATCH
        --capture the error details
        DECLARE @ErrorSeverity INT, 
                @ErrorNumber INT, 
                @ErrorMessage NVARCHAR(4000), 
                @ErrorState INT
        SET @ErrorSeverity = ERROR_SEVERITY()
        SET @ErrorNumber = ERROR_NUMBER()
        SET @ErrorMessage = ERROR_MESSAGE()
        SET @ErrorState = ERROR_STATE()

       --put all the errors in a table together
        INSERT INTO @ErrorRecap(AccountName,ErrorMessage)
          SELECT @groupname,@ErrorMessage

         --echo out the supressed error, the try catch allows us to continue processing, isntead of stopping on the first error
        PRINT 'Msg ' + convert(varchar,@ErrorNumber) + ' Level ' + convert(varchar,@ErrorSeverity) + ' State ' + Convert(varchar,@ErrorState)
        PRINT @ErrorMessage
    END CATCH
    FETCH NEXT FROM c1 INTO @groupname
    END
  CLOSE c1
  DEALLOCATE c1

--display both results and errors
SELECT * FROM #tmp
SELECT * FROM @ErrorRecap
