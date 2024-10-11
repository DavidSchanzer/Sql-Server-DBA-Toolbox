-- Find foreign keys and check constraints that are not trusted
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists the foreign key constraints that exist but are not trusted (ie. not enforced on existing data).
-- It's important to review these to ensure that this is deliberate (ie. the constraint cannot be trusted because the data may sometimes violate it).

DECLARE @Results TABLE
(
    KeyName VARCHAR(1000) NOT NULL,
    DBCCCheckConstraintsCommand VARCHAR(1000) NOT NULL,
    AlterTableCommand VARCHAR(1000) NOT NULL
);

INSERT INTO @Results
EXEC sp_ineachdb @command = '
SELECT ''['' + s.name + ''].['' + o.name + ''].['' + i.name + '']'' AS KeyName,
       ''DBCC CHECKCONSTRAINTS (''''['' + i.name + '']'''')'' AS DBCCCheckConstraintsCommand,
       ''ALTER TABLE ['' + s.name + ''].['' + o.name + ''] WITH CHECK CHECK CONSTRAINT ['' + i.name + '']'' AS AlterTableCommand
FROM sys.foreign_keys i
    INNER JOIN sys.objects o
        ON i.parent_object_id = o.object_id
    INNER JOIN sys.schemas s
        ON o.schema_id = s.schema_id
WHERE i.is_not_trusted = 1
      AND i.is_not_for_replication = 0;

SELECT ''['' + s.name + ''].['' + o.name + ''].['' + i.name + '']'' AS keyname,
       ''DBCC CHECKCONSTRAINTS (''''['' + i.name + '']'''')'' AS DBCCCheckConstraintsCommand,
       ''ALTER TABLE ['' + s.name + ''].['' + o.name + ''] WITH CHECK CHECK CONSTRAINT ['' + i.name + '']'' AS AlterTableCommand
FROM sys.check_constraints i
    INNER JOIN sys.objects o
        ON i.parent_object_id = o.object_id
    INNER JOIN sys.schemas s
        ON o.schema_id = s.schema_id
WHERE i.is_not_trusted = 1
      AND i.is_not_for_replication = 0
      AND i.is_disabled = 0;',
                 @user_only = 1;

SELECT KeyName,
       DBCCCheckConstraintsCommand,
       AlterTableCommand
FROM @Results;