-- Plan Cache queries - probe residuals
-- Part of the SQL Server DBA Toolbox at https://github.com/DavidSchanzer/Sql-Server-DBA-Toolbox
-- This script lists all queries in the Plan Cache that have any probe residuals in the current database.

SET STATISTICS PROFILE OFF;
GO

DECLARE @dbname sysname = QUOTENAME(DB_NAME());

WITH XMLNAMESPACES
(
    DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
)
SELECT Probes.query_plan,
       Probes.BuildSchema,
       Probes.BuildTable,
       Probes.BuildColumn,
       [ic].[DATA_TYPE] AS [BuildColumnType],
       ISNULL(
                 CAST([ic].[CHARACTER_MAXIMUM_LENGTH] AS NVARCHAR),
                 (CAST([ic].[NUMERIC_PRECISION] AS NVARCHAR) + N',' + CAST([ic].[NUMERIC_SCALE] AS NVARCHAR))
             ) AS [BuildColumnLength],
       Probes.ProbeSchema,
       Probes.ProbeTable,
       Probes.ProbeColumn,
       [ic2].[DATA_TYPE] AS [ProbeColumnType],
       ISNULL(
                 CAST([ic2].[CHARACTER_MAXIMUM_LENGTH] AS NVARCHAR),
                 (CAST([ic2].[NUMERIC_PRECISION] AS NVARCHAR) + N',' + CAST([ic2].[NUMERIC_SCALE] AS NVARCHAR))
             ) AS [ProbeColumnLength]
FROM
(
    SELECT qp.query_plan,
           [t].[value](N'(../HashKeysBuild/ColumnReference/@Schema)[1]', N'NVARCHAR(129)') AS [BuildSchema],
           [t].[value](N'(../HashKeysBuild/ColumnReference/@Table)[1]', N'NVARCHAR(129)') AS [BuildTable],
           [t].[value](N'(../HashKeysBuild/ColumnReference/@Column)[1]', N'NVARCHAR(129)') AS [BuildColumn],
           [t].[value](N'(../HashKeysProbe/ColumnReference/@Schema)[1]', N'NVARCHAR(129)') AS [ProbeSchema],
           [t].[value](N'(../HashKeysProbe/ColumnReference/@Table)[1]', N'NVARCHAR(129)') AS [ProbeTable],
           [t].[value](N'(../HashKeysProbe/ColumnReference/@Column)[1]', N'NVARCHAR(129)') AS [ProbeColumn]
    FROM [sys].[dm_exec_cached_plans] AS [cp]
        CROSS APPLY [sys].[dm_exec_query_plan](cp.plan_handle) AS [qp]
        CROSS APPLY [query_plan].[nodes](N'/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS batch(stmt)
        CROSS APPLY [stmt].[nodes](N'.//Hash/ProbeResidual') AS [n]([t])
    WHERE [t].[exist](N'../HashKeysProbe/ColumnReference[@Database=sql:variable("@dbname")][@Schema!="[sys]"]') = 1
) AS [Probes]
    LEFT JOIN INFORMATION_SCHEMA.COLUMNS AS ic
        ON QUOTENAME(ic.TABLE_SCHEMA) = Probes.BuildSchema
           AND QUOTENAME(ic.TABLE_NAME) = Probes.BuildTable
           AND [ic].[COLUMN_NAME] = Probes.BuildColumn
    LEFT JOIN INFORMATION_SCHEMA.COLUMNS AS ic2
        ON QUOTENAME(ic2.TABLE_SCHEMA) = Probes.ProbeSchema
           AND QUOTENAME(ic2.TABLE_NAME) = Probes.ProbeTable
           AND [ic2].[COLUMN_NAME] = Probes.ProbeColumn
WHERE [ic].[DATA_TYPE] <> [ic2].[DATA_TYPE]
      OR
      (
          [ic].[DATA_TYPE] = [ic2].[DATA_TYPE]
          AND ISNULL(
                        CAST([ic].[CHARACTER_MAXIMUM_LENGTH] AS NVARCHAR),
                        (CAST([ic].[NUMERIC_PRECISION] AS NVARCHAR) + N',' + CAST([ic].[NUMERIC_SCALE] AS NVARCHAR))
                    ) <> ISNULL(
                                   CAST([ic2].[CHARACTER_MAXIMUM_LENGTH] AS NVARCHAR),
                                   (CAST([ic2].[NUMERIC_PRECISION] AS NVARCHAR) + N','
                                    + CAST([ic2].[NUMERIC_SCALE] AS NVARCHAR)
                                   )
                               )
      )
OPTION (MAXDOP 1);
GO
