-- DBCC SHRINKFILE iteratively
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script iteratively shrinks the nominated fileid (normally set to 1 for the primary data file) to 99% of its current size.
-- This is generally a much better strategy than trying to remove all available free space in one go, and also allows for frequent incremental gains.
-- Once this is complete, the Ola Hallengren IndexOptimize job should be run.

DECLARE @LogicalFileName	SYSNAME,
		@TargetSizeMB		INT,
		@Factor				FLOAT = .99;

SELECT @LogicalFileName = name FROM sys.sysfiles WHERE fileid = 1;
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
