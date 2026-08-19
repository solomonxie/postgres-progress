# RDS to Self-Hosted PostgreSQL 17

Notes and small scripts for migrating a database off a managed RDS
instance onto a self-hosted PostgreSQL 17 cluster, such as the one in
`../pg_cluster_solotions/patroni_etcd/`.

This folder intentionally stays minimal: it captures the migration
pattern, not a full deployment. The cluster itself (Patroni, etcd,
HAProxy, pgbouncer) lives in `../pg_cluster_solotions/patroni_etcd/`.

## Migration approach

1. Snapshot the RDS instance before starting, as a rollback point.
2. Run the pre-migration checks (`pre_migration_checks.sql`) to
   understand table sizes, active connections, and existing roles
   before moving anything.
3. Recreate roles and grants on the target cluster
   (`roles_example.sql` shows the pattern: broad reader/writer roles,
   then per-application roles that inherit from them).
4. Dump and restore the data (`dump_and_restore_example.sh`), using
   `pg_dump -F d -j N` for parallel dump/restore on larger databases.
5. Point a read-only client at the new cluster and compare row counts
   and a few sampled queries against the source before cutover.
6. Switch application connection strings (or pgbouncer/HAProxy
   routing) from the RDS endpoint to the new cluster, monitoring
   connections and error rates during the switch.
7. Keep the RDS instance available, but idle, for a rollback window
   before decommissioning it.

## Files

- `pre_migration_checks.sql`: generic queries for table sizes, current
  connections, and existing roles, run against the source database
  before migrating.
- `roles_example.sql`: a generic pattern for setting up shared
  reader/writer roles plus per-application roles on the target
  cluster.
- `dump_and_restore_example.sh`: a generic `pg_dump` / `pg_restore`
  walkthrough for moving one database from RDS to the new cluster.
- `verify_connection.py`: a small script to confirm the target
  PostgreSQL 17 cluster is reachable and returns the expected version,
  useful as a first check after cutover.

## Why self-host Postgres

Managed services like RDS trade cost and control for convenience. This
repo explores what it takes to run PostgreSQL reliably by hand: failover,
connection pooling, backups, monitoring, and migration, so that tradeoff
is an informed one rather than a default.


## Notes

All hostnames, database names, and credentials here are placeholders.
