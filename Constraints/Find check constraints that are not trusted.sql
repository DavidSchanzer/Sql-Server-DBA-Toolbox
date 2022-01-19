SELECT	o.name, i.name
FROM	sys.check_constraints i
		INNER JOIN sys.objects o ON i.parent_object_id = o.object_id
		INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE	i.is_not_trusted = 1
		AND i.is_not_for_replication = 0
		AND i.is_disabled = 0
