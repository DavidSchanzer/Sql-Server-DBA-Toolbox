DECLARE @CorrectedCount INT
DECLARE @FailedCount INT
DECLARE UntrustedForeignKeysCursor CURSOR
FOR
        SELECT  '[' + s.name + '].' + '[' + o.name + ']' AS TableName
               ,i.name AS FKName
        FROM    sys.foreign_keys i
                INNER JOIN sys.objects o ON i.parent_object_id = o.OBJECT_ID
                INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
        WHERE   i.is_not_trusted = 1
                AND i.is_not_for_replication = 0
                AND i.is_disabled = 0
        ORDER BY o.name 

DECLARE @TableName AS VARCHAR(200)
DECLARE @FKName AS VARCHAR(200)

SET @CorrectedCount = 0
SET @FailedCount = 0

OPEN UntrustedForeignKeysCursor
FETCH NEXT FROM UntrustedForeignKeysCursor INTO @TableName, @FKName
WHILE @@FETCH_STATUS = 0 
      BEGIN
			/* SELECT 'ALTER TABLE ' + @TableName + ' WITH CHECK CHECK CONSTRAINT [' + @FKName + ']' */

            BEGIN TRY
				/*
					This try-catch will allow the process to continue when a constaint fails to get re-trusted
				*/
                  EXECUTE('ALTER TABLE ' + @TableName + ' WITH CHECK CHECK CONSTRAINT [' + @FKName + ']')
                  SET @CorrectedCount = @CorrectedCount + 1
            END TRY
            BEGIN CATCH
				  SELECT 'Failed table / KEY: ' + @TableName + ' / ' + @FKName
                  SET @FailedCount = @FailedCount + 1
            END CATCH


            FETCH NEXT FROM UntrustedForeignKeysCursor INTO @TableName,
                  @FKName
      END

CLOSE UntrustedForeignKeysCursor
DEALLOCATE UntrustedForeignKeysCursor
SELECT  CAST(@CorrectedCount AS VARCHAR(10)) + ' constraints re-trusted.'
SELECT  CAST(@FailedCount AS VARCHAR(10)) + ' constraints unable to be re-trusted.'
