-- Create logins on AlwaysOn Secondary with same SID as Primary
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script generates CREATE LOGIN statements when run on the Primary node of an Availability Group, with explicit SID values for
-- SQL Authentication logins, to be then executed on the Secondary node. This can be useful as a means to either create all logins on a
-- Secondary node at once when it is being set up, or an individual SQL Authentication login when the Primary and Secondary nodes have
-- different SIDs and therefore have permission issues after a failover.

SELECT 'CREATE LOGIN [' + p.name + '] ' + CASE
                                              WHEN p.type IN ( 'U', 'G' ) THEN
                                                  'FROM WINDOWS '
                                              ELSE
                                                  ''
                                          END + 'WITH '
       + CASE
             WHEN p.type = 'S' THEN
                 'PASSWORD = ' + master.sys.fn_varbintohexstr(l.password_hash) + ' HASHED, ' + 'SID = '
                 + master.sys.fn_varbintohexstr(l.sid) + ', CHECK_EXPIRATION = '
                 + CASE
                       WHEN l.is_expiration_checked > 0 THEN
                           'ON, '
                       ELSE
                           'OFF, '
                   END + 'check_policy = ' + CASE
                                                 WHEN l.is_policy_checked > 0 THEN
                                                     'ON, '
                                                 ELSE
                                                     'OFF, '
                                             END + CASE
                                                       WHEN l.credential_id > 0 THEN
                                                           'CREDENTIAL = ' + c.name + ', '
                                                       ELSE
                                                           ''
                                                   END
             ELSE
                 ''
         END + 'DEFAULT_DATABASE = ' + p.default_database_name
       + CASE
             WHEN LEN(p.default_language_name) > 0 THEN
                 ', DEFAULT_LANGUAGE = ' + p.default_language_name
             ELSE
                 ''
         END
FROM sys.server_principals p
    LEFT JOIN sys.sql_logins l
        ON p.principal_id = l.principal_id
    LEFT JOIN sys.credentials c
        ON l.credential_id = c.credential_id
WHERE p.type IN ( 'S', 'U', 'G' )
      AND p.name <> 'sa'
ORDER BY p.name;
