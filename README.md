# Postgres References

This repo is a personal reference for exploring PostgreSQL: how it works,
how to run it well, and how to operate it outside of a managed service.

The mission is simple: try things out, keep notes, and build small,
working examples instead of relying on memory or scattered links.

## Contents

- `pg_cluster_solotions/`: self-managed PostgreSQL high-availability
  cluster designs (Patroni for leader election, HAProxy for routing,
  pgbouncer for pooling), with a couple of interchangeable
  distributed-configuration-store backends. Each solution folder
  includes its own Terraform to provision the infrastructure it runs
  on.
- `aws_rds_to_pg17/`: notes and scripts for migrating a database off a
  managed RDS instance onto a self-hosted PostgreSQL 17 cluster, such
  as the ones under `pg_cluster_solotions/`.

Each folder has its own README with more detail.

## How it fits together

`pg_cluster_solotions/patroni_etcd/` is the main reference design: a
3-node PostgreSQL cluster where Patroni handles failover, etcd tracks
who's the leader, HAProxy routes clients to the right node, and
pgbouncer pools connections. `patroni_zookeeper/` is the same design
with ZooKeeper standing in for etcd, it only documents what's
different rather than duplicating the whole setup.

`aws_rds_to_pg17/` is the other direction: once a cluster like that
exists, how do you actually move a database onto it from RDS without
losing data or an afternoon.

## How to play around

1. Read `pg_cluster_solotions/patroni_etcd/README.md` for the design
   and the diagram of how Patroni, etcd, HAProxy, and pgbouncer fit
   together.
2. Provision three nodes with the Terraform in
   `pg_cluster_solotions/patroni_etcd/terraform/` (or point the setup
   scripts at any three machines you already have, real or local VMs).
3. Use the `Makefile` in `pg_cluster_solotions/patroni_etcd/` to walk
   through the setup scripts in order (`make help` lists every step),
   or run them by hand if you'd rather read as you go.
4. Once the cluster is up, work through `tests/test_ha.sh` to kill
   nodes, processes, and network paths, and watch Patroni fail over.
5. Try `pg_cluster_solotions/patroni_zookeeper/README.md` to see how
   little needs to change to swap the DCS backend.
6. If you want to practice a real migration, `aws_rds_to_pg17/` walks
   through moving a database from RDS onto the cluster you just built.

## Why self-host Postgres

Managed services like RDS trade cost and control for convenience. This
repo explores what it takes to run PostgreSQL reliably by hand: failover,
connection pooling, backups, monitoring, and migration, so that tradeoff
is an informed one rather than a default.

## Status

This is an ongoing personal lab, not a production template. Configs use
placeholder values (IPs, hostnames, credentials) and need real values
filled in before use anywhere.
