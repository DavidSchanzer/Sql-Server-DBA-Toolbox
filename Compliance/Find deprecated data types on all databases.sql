DECLARE @sql VARCHAR(MAX)
    = 'SELECT ''?'' AS [Database], s.[name] AS SchemaName, 
           t.[name] AS TableName, 
           c.[name] AS ColumnName,
           typ.[name] + CASE WHEN typ.[name] IN (N''decimal'', N''numeric'')
                             THEN N''('' + CAST(c.precision AS nvarchar(20)) + N'', '' 
                                  + CAST(c.scale AS nvarchar(20)) + N'')''
                             WHEN typ.[name] IN (N''varchar'', N''nvarchar'', N''char'', N''nchar'')
                             THEN N''('' + CASE WHEN c.max_length < 0 
                                              THEN N''max'' 
                                              ELSE CAST(c.max_length AS nvarchar(20)) 
                                         END + N'')''
                             WHEN typ.[name] IN (N''time'', N''datetime2'', N''datetimeoffset'')
                             THEN N''('' + CAST(c.scale AS nvarchar(20)) + N'')''
                             ELSE N''''
                        END AS DataType,
            CASE typ.[name] WHEN N''image'' THEN ''varbinary(max)''
                            WHEN N''text'' THEN ''varchar(max)''
                            WHEN N''ntext'' THEN ''nvarchar(max)''
            END AS SuggestedReplacementType
    FROM sys.schemas AS s
    INNER JOIN sys.tables AS t
        ON s.[schema_id] = t.[schema_id]
    INNER JOIN sys.columns AS c
        ON t.[object_id] = c.[object_id] 
    INNER JOIN sys.[types] AS typ 
        ON c.system_type_id = typ.system_type_id
        AND c.user_type_id = typ.user_type_id 
    WHERE t.[type] = N''U''
    AND typ.[name] IN (''image'', ''text'', ''ntext'')
    ORDER BY SchemaName, TableName, c.column_id;';
EXEC dbo.sp_ineachdb @command = @sql;
