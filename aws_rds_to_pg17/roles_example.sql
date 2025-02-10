/* NOTE:
    When combining several source databases onto one cluster, expect
    role name and permission conflicts. Set up broad reader/writer
    roles first, then grant application-specific roles from them.
*/

-- Root roles (can access everything in a database once granted) --
CREATE ROLE admin_writer WITH LOGIN NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOREPLICATION NOBYPASSRLS;
CREATE ROLE admin_reader WITH LOGIN NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOREPLICATION NOBYPASSRLS;

-- [Run below setup in each target database] --
-- <writer>
GRANT SELECT, INSERT, DELETE, UPDATE ON ALL TABLES IN SCHEMA public TO admin_writer;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO admin_writer;
GRANT USAGE ON SCHEMA public TO admin_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, DELETE, UPDATE ON TABLES TO admin_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO admin_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO admin_writer;
-- <reader>
GRANT SELECT ON ALL TABLES IN SCHEMA public TO admin_reader;
GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA public TO admin_reader;
GRANT USAGE ON SCHEMA public TO admin_reader;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO admin_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO admin_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, USAGE ON SEQUENCES TO admin_reader;

\c app_db
-- Repeat the writer/reader grants above for each database being migrated...


-- Per-application roles, inheriting from the shared roles --

-- [example service] --
CREATE ROLE app_service_updater INHERIT; GRANT admin_writer TO app_service_updater;
GRANT USAGE, SELECT, UPDATE ON SEQUENCE some_table_id_seq TO admin_writer;

-- [read-only analytics access] --
CREATE ROLE analytics_reader INHERIT; GRANT admin_reader TO analytics_reader;

-- [dev/debug access] --
CREATE ROLE dev_readonly INHERIT; GRANT admin_reader TO dev_readonly;
