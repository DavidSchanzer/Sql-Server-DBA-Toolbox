SELECT 'The tempdb database has multiple data files in one filegroup, but they are not all set up with the same initial size or to grow in identical amounts.  This can lead to uneven file activity inside the filegroup.'
			FROM tempdb.sys.database_files 
			WHERE type_desc = 'ROWS' 
			GROUP BY data_space_id 
			HAVING COUNT(DISTINCT size) > 1 OR COUNT(DISTINCT growth) > 1 OR COUNT(DISTINCT is_percent_growth) > 1
