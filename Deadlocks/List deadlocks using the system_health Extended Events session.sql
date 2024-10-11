-- List deadlocks using the system_health Extended Events session
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script queries the default system_health Extended Events session for deadlocks, returning the output in XML.
-- To view the deadlock graph in a graphical format, click on the DeadlockGraph XML, then save as a file with a .xdl extension, then open the file in SSMS.

SELECT CONVERT(XML, event_data).value('(event[@name="xml_deadlock_report"]/@timestamp)[1]', 'datetime') AS DeadlockDateTime,
       CONVERT(XML, event_data).query('/event/data/value/child::*') AS DeadlockGraph
FROM sys.fn_xe_file_target_read_file('system_health*.xel', NULL, NULL, NULL)
WHERE object_name LIKE 'xml_deadlock_report';
