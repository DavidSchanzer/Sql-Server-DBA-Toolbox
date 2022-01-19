DECLARE @LogicalFileName	SYSNAME,
		@TargetSizeMB		INT,
		@Factor				FLOAT = .99;

SELECT @LogicalFileName = name FROM sysfiles WHERE fileid = 1;
SELECT @TargetSizeMB = 1 + size * 8.0 / 1024 FROM sys.database_files WHERE name = @LogicalFileName;

WHILE @TargetSizeMB > 0
BEGIN
    SET @TargetSizeMB = @TargetSizeMB * @Factor;
    DBCC SHRINKFILE( @LogicalFileName, @TargetSizeMB );
    DECLARE @msg VARCHAR(200) = CONCAT('Shrink file completed. Target Size: ', @TargetSizeMB, ' MB. Timestamp: ', CURRENT_TIMESTAMP);
    RAISERROR(@msg, 1, 1) WITH NOWAIT;
    WAITFOR DELAY '00:00:01';
END
GO
