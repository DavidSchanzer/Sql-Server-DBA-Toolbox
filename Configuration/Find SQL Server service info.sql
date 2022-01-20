-- Find SQL Server service info
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script returns information on the installed SQL Server services, and the ports on which they are listening

SELECT servicename,
       startup_type_desc,
       status_desc,
       last_startup_time,
       service_account,
       is_clustered,
       cluster_nodename,
       instant_file_initialization_enabled
FROM sys.dm_server_services;

SELECT registry_key,
       value_name,
       value_data
FROM sys.dm_server_registry
WHERE value_name LIKE '%Port%'
      AND registry_key LIKE '%IPAll';
