-- Tracking problematic page splits in Extended Events
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script creates an Extended Events session called "BadPageSplits" to track LOP_DELETE_SPLIT transaction_log operations in the server.
-- It includes a query to parse the data collected.
-- From https://www.simple-talk.com/blogs/2016/03/14/how-to-identify-the-source-of-page-splits-in-a-database/

CREATE EVENT SESSION [BadPageSplits]
ON SERVER
    ADD EVENT sqlserver.transaction_log
    (WHERE operation = 11 -- LOP_DELETE_SPLIT 
    )
    ADD TARGET package0.event_file
    -- You need to customize the path
    (SET filename = N'C:\Temp\BadPageSplits.xel');
GO

-- Start the Event Session
ALTER EVENT SESSION [BadPageSplits] ON SERVER STATE = START;
GO

-- Determine database
WITH qry
AS (SELECT
        -- Retrieve the database_id from inside the XML document
        theNodes.event_data.value('(data[@name="database_id"]/value)[1]', 'int') AS database_id
    FROM
    (
        SELECT CONVERT(XML, event_data) event_data -- convert the text field to XML
        FROM
            -- reads the information in the event files
            sys.fn_xe_file_target_read_file('C:\Temp\BadPageSplits*.xel', NULL, NULL, NULL)
    ) theData
        CROSS APPLY theData.event_data.nodes('//event') theNodes(event_data) )
SELECT DB_NAME(qry.database_id),
       COUNT(*) AS total
FROM qry
GROUP BY DB_NAME(qry.database_id) -- group the result by database
ORDER BY total DESC;

-- Query Target Data to get the top splitting objects in the database:
WITH qry
AS (SELECT theNodes.event_data.value('(data[@name="database_id"]/value)[1]', 'int') AS database_id,
           theNodes.event_data.value('(data[@name="alloc_unit_id"]/value)[1]', 'varchar(30)') AS alloc_unit_id,
           theNodes.event_data.value('(data[@name="context"]/text)[1]', 'varchar(30)') AS context
    FROM
    (
        SELECT CONVERT(XML, event_data) event_data
        FROM sys.fn_xe_file_target_read_file('C:\Temp\BadPageSplits*.xel', NULL, NULL, NULL)
    ) AS theData
        CROSS APPLY theData.event_data.nodes('//event') AS theNodes(event_data) )
SELECT ob.name,
       qry.context,
       COUNT(*) AS total -- The count of splits by objects
FROM qry
    INNER JOIN sys.allocation_units au
        ON qry.alloc_unit_id = au.allocation_unit_id
    INNER JOIN sys.partitions p
        ON au.container_id = p.hobt_id
    INNER JOIN sys.objects ob
        ON p.object_id = ob.object_id
WHERE au.type IN ( 1, 3 )
      AND DB_NAME(qry.database_id) = '<DatabaseName>' -- Filter by the database
GROUP BY ob.name,
         qry.context -- group by object name and context
ORDER BY ob.name;

-- Stop the Event Session
ALTER EVENT SESSION [BadPageSplits] ON SERVER STATE = STOP;
GO

-- Drop the Event Session
DROP EVENT SESSION [BadPageSplits] ON SERVER;
GO
