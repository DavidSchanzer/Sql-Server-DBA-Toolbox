IF CONVERT(VARCHAR(2), SERVERPROPERTY('productversion')) = '15'
BEGIN
    SELECT *
    FROM sys.databases
    WHERE database_id > 4
          AND name NOT LIKE 'ReportServer%'
          AND is_accelerated_database_recovery_on = 0;
END;
