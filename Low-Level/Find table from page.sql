-- Find table from page
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script allows you to specify a database name and a page ID and it will return the name of the relevant table and index that contains
-- that page ID, if appropriate.

DECLARE @DatabaseName VARCHAR(255) = '<DBName>';
DECLARE @PageID VARCHAR(20) = '<PageID>';
DECLARE @DBCCPAGE TABLE
(
    ParentObject VARCHAR(50) NOT NULL,
    Object VARCHAR(50) NOT NULL,
    Field VARCHAR(50) NOT NULL,
    Value VARCHAR(50) NOT NULL
);
DECLARE @ObjectId BIGINT,
        @IndexId BIGINT;

INSERT INTO @DBCCPAGE
(
    ParentObject,
    Object,
    Field,
    Value
)
EXECUTE ('DBCC PAGE( ' + @DatabaseName + ', 1, ' + @PageID + ', 0 ) WITH TABLERESULTS');

SELECT @ObjectId = Value
FROM @DBCCPAGE AS d
WHERE Field = 'Metadata: ObjectId';
SELECT @IndexId = Value
FROM @DBCCPAGE AS d
WHERE Field = 'Metadata: IndexId';

SELECT @PageID AS PageId,
       @ObjectId AS ObjectID,
       OBJECT_NAME(@ObjectId) AS ObjectName,
       @IndexId AS IndexID,
       (
           SELECT name
           FROM sys.indexes
           WHERE object_id = @ObjectId
                 AND index_id = @IndexId
       ) AS IndexName;
GO
