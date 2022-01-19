CREATE EVENT SESSION [PRMS_Rhapsody_Stats_Lock_Acquired] ON SERVER 
ADD EVENT sqlserver.lock_acquired (WHERE ((([mode]=('IX')) OR ([mode]=('X'))) AND ([object_id]=(1435152158))))
ADD TARGET package0.event_file(SET filename=N'c:\temp\PRMS_Rhapsody_Stats_Lock_Acquired')
GO

SELECT OBJECT_ID(N'Rhapsody.Stats')	-- 1435152158
