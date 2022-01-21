-- Run DBCC CHECKCONSTRAINTS for all foreign key and check constraints
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script runs DBCC CHECKCONSTRAINTS with arguments ALL_CONSTRAINTS and ALL_ERRORMSGS and displays any output

DROP TABLE IF EXISTS #CheckConstraints;
GO

CREATE TABLE #CheckConstraints
(
    TableName VARCHAR(255) NOT NULL,
    ConstraintName VARCHAR(255) NOT NULL,
    WhereClause VARCHAR(255) NOT NULL
);
GO

DECLARE @sql NVARCHAR(255) = N'DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS, ALL_ERRORMSGS';
INSERT INTO #CheckConstraints
(
    TableName,
    ConstraintName,
    WhereClause
)
EXEC sp_executesql @stmt = @sql;
GO

SELECT TableName,
       ConstraintName,
       COUNT(*)
FROM #CheckConstraints
GROUP BY TableName,
         ConstraintName
ORDER BY TableName,
         ConstraintName;
GO

SELECT TableName,
       ConstraintName,
       WhereClause
FROM #CheckConstraints
ORDER BY TableName,
         ConstraintName,
         WhereClause;
GO
