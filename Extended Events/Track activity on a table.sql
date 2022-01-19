CREATE EVENT SESSION PRMS_Rhapsody_Stats ON SERVER
ADD EVENT sqlserver.sql_batch_completed (SET collect_batch_text = (1) ACTION (sqlserver.sql_text) WHERE ([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name], N'PRMS') AND [sqlserver].[like_i_sql_unicode_string]([batch_text], N'%Rhapsody.Stats%'))),
ADD EVENT sqlserver.rpc_completed (ACTION(sqlserver.sql_text) WHERE (([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name],N'PRMS'))))
ADD TARGET package0.event_file (SET filename = N'PRMS_Rhapsody_Stats');

SELECT OBJECT_ID(N'Rhapsody.Usp_ErrorLookup')						-- 1911677858
SELECT OBJECT_ID(N'Rhapsody.Usp_WriteStatsInitialSIU')				-- 2007678200
SELECT OBJECT_ID(N'Rhapsody.Usp_WriteStatsORU')						-- 2023678257
SELECT OBJECT_ID(N'Rhapsody.Usp_WriteStatsORUMessageOnly')			-- 2039678314
SELECT OBJECT_ID(N'Rhapsody.Usp_WriteStatsSIU')						-- 2055678371
SELECT OBJECT_ID(N'Rhapsody.Usp_WriteStatsSIUACKOnly')				-- 2071678428
SELECT OBJECT_ID(N'Rhapsody.Usp_WriteStatsSIUaddJSONMessageOnly')	-- 2103678542

SELECT OBJECT_ID(N'Rhapsody.Stats')	-- 1435152158
