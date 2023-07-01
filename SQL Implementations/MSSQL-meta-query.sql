-- query tables for a given column name
SELECT DISTINCT c.name as [ColumnName], y.name as [DataType], c.is_nullable as [Nullable],
	s.name [Schema], t.name as [TableName], 
	FORMAT(ROUND(p.rows, 1 - FLOOR(LOG10(p.rows+1))), '#,###,###,###') [Rows]
FROM sys.columns c
	JOIN sys.tables  t    ON c.object_id = t.object_id
	JOIN sys.types   y    ON c.user_type_id = y.user_type_id
	JOIN sys.partitions p ON t.object_id = p.object_id
	JOIN sys.schemas s	  ON s.schema_id = t.schema_id
WHERE c.name LIKE '%%'
	and s.name LIKE '%'
	and t.name like '%%'
	and p.rows > 0 -- ignores empty tables
	--and y.name like '%char%'
ORDER BY TableName, ColumnName;


-- query column names for a given table
SELECT c.name as [ColumnName], y.name as [DataType], COLUMNPROPERTY(t.object_id, c.name, 'PRECISION') as [Defined Max Length], c.is_nullable as [Nullable],
	s.name [Schema], t.name [TableName]
FROM sys.columns c
	JOIN sys.tables  t    ON c.object_id = t.object_id
	JOIN sys.types   y    ON c.user_type_id = y.user_type_id
	JOIN sys.schemas s	  ON s.schema_id = t.schema_id
WHERE s.name LIKE '%'
	and t.name LIKE '%%'
ORDER BY TableName, ColumnName;


-- query dimensions of all tables
SELECT s.name [Schema], t.name as [TableName], COUNT(DISTINCT c.column_id) [Columns] 
	, ROUND(p.rows, 1 - FLOOR(LOG10(p.rows+1))) as "n_rows" 
	, ROUND(p.rows, 1 - FLOOR(LOG10(p.rows+1))) * COUNT(DISTINCT c.column_id) as n_values 
	, ROUND(((SUM(au.data_pages) * 2) / 1024.00), 0) AS data_space_MB
	, ROUND(((SUM(au.used_pages) * 2) / 1024.00), 0) AS used_space_MB 
FROM sys.columns c
	JOIN sys.tables  t    ON c.object_id = t.object_id
	JOIN sys.schemas s	  ON s.schema_id = t.schema_id
	JOIN sys.partitions p ON t.object_id = p.object_id
	JOIN sys.allocation_units au on au.container_id = p.partition_id
WHERE s.name like '%' 
	and t.name like '%%'
	--and p.rows > 0 -- ignores empty tables
GROUP BY s.name, t.name, p.rows
ORDER BY n_rows desc
;

-- listing of all stored procedures
SELECT * 
FROM sys.procedures 
ORDER BY sys.procedures.name