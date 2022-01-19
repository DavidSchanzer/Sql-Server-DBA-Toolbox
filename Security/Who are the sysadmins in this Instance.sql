SELECT   p.name, p.type_desc, p.is_disabled
FROM     master.sys.server_principals AS p
JOIN sys.syslogins s ON p.sid = s.sid
WHERE    s.sysadmin = 1
AND p.name NOT IN ( 'BUILTIN\Administrators', 'CI\ZCISAP_SQLSVR_00001', 'CI\ZCISGP_SQL_Server_DBAs', 'sa', 'CI\DSCHA', 'CI\RUCAM', 'dscha', 'NT AUTHORITY\SYSTEM', 'NT Service\MSSQLSERVER', 'CI\sql15_agt_svc', 'CI\SQL13_AGT_SVC', 'CI\sql15_agt_svc', 'CI\ZCISADSQLA' )
AND p.name NOT LIKE 'NT SERVICE\%'
ORDER BY p.name
