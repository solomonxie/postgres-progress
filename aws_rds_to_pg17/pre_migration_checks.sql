-- Run these against the source RDS database before migrating, to know
-- what you're moving and who is currently connected to it.

------------------------------------------------------------------------
--                            TABLE SIZES                              --
------------------------------------------------------------------------

SELECT relname AS table_name,
       pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
       pg_size_pretty(pg_relation_size(relid)) AS table_size,
       pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) AS index_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;


------------------------------------------------------------------------
--                       CURRENT CONNECTIONS                           --
------------------------------------------------------------------------

SELECT client_addr AS ip_addr, COUNT(*) AS query_count
FROM pg_stat_activity
WHERE client_addr IS NOT NULL
GROUP BY client_addr
ORDER BY query_count DESC;

SELECT datname AS dbname, usename AS username, client_addr AS ip_address, COUNT(*) AS query_count
FROM pg_stat_activity
WHERE client_addr IS NOT NULL
GROUP BY datname, usename, client_addr
ORDER BY query_count DESC;


------------------------------------------------------------------------
--                               ROLES                                 --
------------------------------------------------------------------------

\du+
