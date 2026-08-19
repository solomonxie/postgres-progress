# Patroni + ZooKeeper Clustering

The same design as `../patroni_etcd/`, using ZooKeeper instead of etcd
as Patroni's distributed configuration store (DCS). Patroni treats the
DCS as a pluggable backend, so almost nothing else about the cluster
changes.

## What actually differs from patroni_etcd

Three things, everything else (PostgreSQL, Patroni's own behavior,
pgbouncer, HAProxy, pgAdmin, Terraform) is identical to
`../patroni_etcd/`:

1. Install ZooKeeper on each node instead of etcd, and configure a
   3-node ensemble (`zoo.cfg` + a `myid` file per node) instead of
   `etcd.conf.yml`. See `confs/zoo.cfg` below.
2. In each node's `patroni.yml`, replace the `etcd:` section with a
   `zookeeper:` section listing the ensemble hosts. See
   `confs/patroni_dcs_snippet.yml` below, everything else in
   `patroni.yml` (scope, restapi, postgresql, bootstrap) stays the
   same as `../patroni_etcd/manual/node1_conf/patroni.yml`.
3. Install `patroni[zookeeper]` instead of `patroni[etcd]` (swap the
   pip extra in `../patroni_etcd/manual/setup_patroni.sh`).

`patronictl`, the REST API, HAProxy routing, and failover behavior are
unchanged: Patroni still elects a leader and stores it in the DCS, it
just writes that state as ZooKeeper znodes instead of etcd keys.

## Files

- `confs/zoo.cfg`: example 3-node ZooKeeper ensemble config. Copy to
  `/etc/zookeeper/conf/zoo.cfg` on each node (path depends on package,
  e.g. `zookeeperd` on Debian/Ubuntu already ships a systemd unit, so
  there's no equivalent to `common_conf/etcd.service` to write by
  hand).
- `confs/patroni_dcs_snippet.yml`: the only part of `patroni.yml` that
  differs from the etcd version. Drop this in place of the `etcd:`
  block in a copy of
  `../patroni_etcd/manual/node1_conf/patroni.yml` (and node2/node3).

## Setup

Follow `../patroni_etcd/README.md` step by step, with these
substitutions:

1. `setup_ec2.sh`: unchanged.
2. `setup_etcd.sh`: replace with installing `zookeeper` (or
   `zookeeperd`), writing `confs/zoo.cfg` to each node, and creating
   `/var/lib/zookeeper/myid` containing that node's id (`1`, `2`, `3`,
   matching the `server.N` entries in `zoo.cfg`).
3. `setup_pg.sh`: unchanged.
4. `setup_patroni.sh`: install `patroni[zookeeper]` instead of
   `patroni[etcd]`; use a `patroni.yml` built from
   `../patroni_etcd/manual/node1_conf/patroni.yml` with its `etcd:`
   section swapped for `confs/patroni_dcs_snippet.yml`.
5. `setup_pgbouncer.sh`, `setup_haproxy.sh`, `setup_pgadmin.sh`:
   unchanged.

## Why you might pick one over the other

etcd is simpler to run for a small cluster (single static binary, no
JVM) and is what most Patroni tutorials default to. ZooKeeper is worth
using if you already run a ZooKeeper ensemble for something else
(Kafka, for example) and would rather not operate a second DCS.
