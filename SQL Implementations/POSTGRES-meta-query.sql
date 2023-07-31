
-- postgres metadata query

-- all tables and approximate dimensions
SELECT schemaname as "schema", relname as "table_name", n_live_tup as "n_records" 
FROM pg_stat_user_tables 
WHERE schemaname in ('isds_dev')
ORDER BY n_live_tup desc
;

-- all tables and approximate dimensions
SELECT nspname AS "schema", relname as "table_name", reltuples
FROM pg_class C
    LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
WHERE relkind='r' 
	and nspname not in ('pg_catalog', 'information_schema') 
	and nspname in ('isds_dev') 
ORDER BY reltuples desc
;
