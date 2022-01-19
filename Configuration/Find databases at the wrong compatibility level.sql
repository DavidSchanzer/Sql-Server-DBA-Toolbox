SELECT name,
       CAST(SUBSTRING(@@version, CHARINDEX(' - ', @@version) + 3, 2) + '0' AS INTEGER) AS instance_version,
       CAST(compatibility_level AS INTEGER) AS compatibility_level
FROM sys.databases
WHERE CAST(compatibility_level AS INTEGER) <> CAST(SUBSTRING(@@version, CHARINDEX(' - ', @@version) + 3, 2) + '0' AS INTEGER);
