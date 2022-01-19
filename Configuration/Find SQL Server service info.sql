SELECT servicename,
       startup_type_desc,
       status_desc,
       last_startup_time,
       service_account,
       is_clustered,
       cluster_nodename,
       instant_file_initialization_enabled
FROM sys.dm_server_services;

SELECT *
FROM sys.dm_server_registry
WHERE value_name LIKE '%Port%'
      AND registry_key LIKE '%IPAll';
