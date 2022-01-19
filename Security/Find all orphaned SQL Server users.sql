IF OBJECT_ID('TempDB..#Temp', 'U') > 0
    DROP TABLE [#Temp];
CREATE TABLE [#Temp]
(
    [DatabaseName] VARCHAR(255),
    [UserName] VARCHAR(255),
    [TypeDesc] VARCHAR(20),
    [DefaultSchemaName] VARCHAR(255),
    [CreateDate] DATETIME,
    [ModifyDate] DATETIME,
    [DropCommand] VARCHAR(255)
);
INSERT INTO [#Temp]
EXEC [sys].[sp_MSforeachdb] 'USE [?];
		SELECT DB_NAME() [database], name as [user_name], type_desc, default_schema_name, create_date, modify_date, ''USE ['' + DB_NAME() + '']; DROP USER ['' + name + ''];'' AS DropCommand
		from sys.database_principals 
		where type in (''G'',''S'',''U'') 
		and [sid] not in ( select [sid] from sys.server_principals where type in (''G'',''S'',''U'') ) 
		and name not in (''dbo'',''guest'',''INFORMATION_SCHEMA'',''sys'',''MS_DataCollectorInternalUser'')';
SELECT [DatabaseName],
       [UserName],
       [TypeDesc],
       [DefaultSchemaName],
       [CreateDate],
       [ModifyDate],
       [DropCommand]
FROM [#Temp];
DROP TABLE [#Temp];
