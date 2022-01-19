USE master
GO
EXEC sp_ineachdb @command = 'EXEC dbo.sp_SQLskills_finddupes'
GO
