SELECT name AS DatabaseName,
       recovery_model_desc AS RecoveryModel,
       'ALTER DATABASE [' + name + '] SET RECOVERY SIMPLE;' AS SQL
FROM sys.databases
WHERE recovery_model_desc <> 'SIMPLE';
