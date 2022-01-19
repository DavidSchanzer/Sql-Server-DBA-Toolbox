SELECT 'ALTER SERVER AUDIT [' + name + '] WITH (STATE=OFF); DROP SERVER AUDIT [' + name + ']' AS DropCommand,
       sa.audit_id,
       sa.name,
       sa.audit_guid,
       sa.create_date,
       sa.modify_date,
       sa.principal_id,
       sa.type,
       sa.type_desc,
       sa.on_failure,
       sa.on_failure_desc,
       sa.is_state_enabled,
       sa.queue_delay,
       sa.predicate
FROM sys.server_audits AS sa
WHERE NOT EXISTS
(
    SELECT * FROM sys.databases AS d WHERE d.name = sa.name
)
ORDER BY audit_id;
