EXEC sp_MSforeachdb 'USE [?]; SELECT ''?'' AS DatabaseName, OBJECT_NAME(object_id) AS TableName, name AS IndexName, fill_factor FROM sys.indexes WHERE fill_factor != 0'
