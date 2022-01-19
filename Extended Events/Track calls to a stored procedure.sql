DROP EVENT SESSION PRMS_Usp_WriteStatsORU ON SERVER;
GO
CREATE EVENT SESSION PRMS_Usp_WriteStatsORU ON SERVER
ADD EVENT sqlserver.exec_prepared_sql (ACTION(sqlserver.sql_text) WHERE (([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name],N'PRMS')) AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%Usp_WriteStatsORU%')))),
ADD EVENT sqlserver.prepare_sql (ACTION(sqlserver.sql_text) WHERE (([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name],N'PRMS')) AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%Usp_WriteStatsORU%')))),
ADD EVENT sqlserver.rpc_completed (ACTION(sqlserver.sql_text) WHERE (([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name],N'PRMS')) AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%Usp_WriteStatsORU%')))),
ADD EVENT sqlserver.sp_statement_completed (ACTION(sqlserver.sql_text) WHERE (([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name],N'PRMS')) AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%Usp_WriteStatsORU%')))),
ADD EVENT sqlserver.sql_batch_completed (ACTION(sqlserver.sql_text) WHERE (([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name],N'PRMS')) AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%Usp_WriteStatsORU%')))),
ADD EVENT sqlserver.unprepare_sql (ACTION(sqlserver.sql_text) WHERE (([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name],N'PRMS')) AND ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%Usp_WriteStatsORU%'))))
ADD TARGET package0.event_file(SET filename=N'c:\temp\PRMS_Usp_WriteStatsORU.xel')
WITH (TRACK_CAUSALITY = ON);
GO
