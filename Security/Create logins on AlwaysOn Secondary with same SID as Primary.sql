SELECT  'CREATE LOGIN [' + p.name + '] '
        + CASE WHEN p.type IN ( 'U', 'G' ) THEN 'FROM WINDOWS '
               ELSE ''
          END + 'WITH ' + CASE WHEN p.type = 'S'
                               THEN 'PASSWORD = '
                                    + master.sys.fn_varbintohexstr(l.password_hash)
                                    + ' HASHED, ' + 'SID = '
                                    + master.sys.fn_varbintohexstr(l.sid)
                                    + ', CHECK_EXPIRATION = '
                                    + CASE WHEN l.is_expiration_checked > 0
                                           THEN 'ON, '
                                           ELSE 'OFF, '
                                      END + 'check_policy = '
                                    + CASE WHEN l.is_policy_checked > 0
                                           THEN 'ON, '
                                           ELSE 'OFF, '
                                      END
                                    + CASE WHEN l.credential_id > 0
                                           THEN 'CREDENTIAL = ' + c.name
                                                + ', '
                                           ELSE ''
                                      END
                               ELSE ''
                          END + 'DEFAULT_DATABASE = '
        + p.default_database_name
        + CASE WHEN LEN(p.default_language_name) > 0
               THEN ', DEFAULT_LANGUAGE = ' + p.default_language_name
               ELSE ''
          END
FROM    sys.server_principals p
        LEFT JOIN sys.sql_logins l ON p.principal_id = l.principal_id
        LEFT JOIN sys.credentials c ON l.credential_id = c.credential_id
WHERE   p.type IN ( 'S', 'U', 'G' )
        AND p.name <> 'sa'
