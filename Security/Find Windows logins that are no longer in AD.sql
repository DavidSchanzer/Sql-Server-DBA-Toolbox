DECLARE @user sysname;

DECLARE recscan CURSOR
FOR
    SELECT  name
    FROM    sys.server_principals
    WHERE   type LIKE '[UG]'
            AND name LIKE 'CI\_____';

OPEN recscan; 
FETCH NEXT FROM recscan INTO @user;

WHILE @@fetch_status = 0
	BEGIN
		DROP TABLE #Temp;
		CREATE TABLE #Temp
			(
				AccountName VARCHAR(255),
				Type VARCHAR(10),
				Privilege VARCHAR(10),
				MappedLoginName VARCHAR(255),
				PermissionPath VARCHAR(255)
			);
		BEGIN TRY
			INSERT  INTO #Temp
					EXEC xp_logininfo @user;
		END TRY
		BEGIN CATCH
		--Error on xproc because login doesn't exist
			PRINT 'drop login ' + CONVERT(VARCHAR, @user);
		END CATCH;

		DROP TABLE #Temp;
		FETCH NEXT FROM recscan INTO @user;
	END;

CLOSE recscan;
DEALLOCATE recscan;
