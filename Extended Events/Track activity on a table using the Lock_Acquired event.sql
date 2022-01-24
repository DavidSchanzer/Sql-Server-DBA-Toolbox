-- Track activity on a table using the Lock_Acquired event
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script creates an Extended Events session called "Lock_Acquired" that uses the lock_acquired event to track DML statements on a table.

CREATE EVENT SESSION [Lock_Acquired] ON SERVER 
ADD EVENT sqlserver.lock_acquired (WHERE ((([mode]=('IX')) OR ([mode]=('X'))) AND ([object_id]=(<ObjectId>))))
ADD TARGET package0.event_file(SET filename=N'c:\temp\Lock_Acquired')
GO
