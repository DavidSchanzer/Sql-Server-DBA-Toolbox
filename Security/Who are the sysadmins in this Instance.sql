-- Who are the sysadmins in this Instance
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists all logins that are members of the sysadmin fixed server role.

SELECT   p.name, p.type_desc, p.is_disabled
FROM     master.sys.server_principals AS p
JOIN sys.syslogins s ON p.sid = s.sid
WHERE    s.sysadmin = 1
AND p.name NOT IN ( 'BUILTIN\Administrators', 'sa', 'NT AUTHORITY\SYSTEM' )
AND p.name NOT LIKE 'NT SERVICE\%'
ORDER BY p.name
