-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script returns, for each encrypted database, the name of the certificate that was used to encrypt it.
-- This can be useful when an instance (eg. Test) has some databases that were restored from other instances (eg. Prod).

SELECT DB_NAME(dek.database_id) AS DatabaseName,
       c.name AS EncryptingCertificate,
       c.thumbprint AS CertificateThumbprint
FROM sys.dm_database_encryption_keys AS dek
    INNER JOIN sys.certificates AS c
        ON c.thumbprint = dek.encryptor_thumbprint
ORDER BY DatabaseName;
