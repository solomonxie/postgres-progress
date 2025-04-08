# Ansible

An automated version of `../manual/`: the same install/configure steps
for etcd, PostgreSQL, Patroni, pgbouncer, HAProxy, and pgAdmin, as an
Ansible playbook instead of a runbook you copy-paste by hand.
Ansible's job here stops at software and config, it installs
packages, deploys config files, and starts services. It doesn't
provision the underlying machines (that's `../terraform/`) and it
doesn't touch cluster failover logic (that's Patroni's job, at
runtime).

The config files it deploys are the real ones in `../manual/`, not
copies, this playbook just automates getting them onto the right node
and starting the right service, the same as the manual steps in
`../manual/README.md` describe.

## Layout

- `ansible.cfg`: points Ansible at `inventory/` and `roles/`
- `inventory/hosts.ini`: node groups (`etcd_nodes`, `pg_nodes`,
  `proxy_nodes`) and placeholder connection details
- `group_vars/all.yml`: shared variables (venv path, PostgreSQL
  version, data disk device, pgAdmin credentials)
- `site.yml`: the main playbook, one play per component, in setup
  order
- `roles/`: one role per component (`common`, `etcd`, `postgresql`,
  `patroni`, `pgbouncer`, `haproxy`, `pgadmin`), each one a direct
  translation of the matching script under `../manual/`

## Setup order

Same order as `../README.md`, encoded as plays in `site.yml`:

1. `common` (all nodes): base packages, Python venv, mount the data disk
2. `etcd` (all nodes, one at a time): install etcd, bootstrap node1,
   then register and start each other node as a member before it joins
3. `postgresql` (node1, node2): install PostgreSQL 17, disable the
   native systemd service
4. `patroni` (node1, node2, one at a time): install Patroni, start it
   on node1 to initialize the cluster, then node2 to join it
5. `pgbouncer` (node1, node2): install and start pgbouncer
6. `haproxy`, `pgadmin` (node3): install and start both

## Usage

Fill in `inventory/hosts.ini` with real addresses (for example, from
`terraform output` in `../terraform/`), then:

```sh
ansible-playbook site.yml
```

Run a single component against a single node while iterating:

```sh
ansible-playbook site.yml --tags etcd --limit node1
ansible-playbook site.yml --list-tasks   # see every task, in order, without running anything
```

## Notes

Most roles are idempotent (safe to re-run): package installs, config
deploys, and `systemd` state all converge. The `etcd` role's member
registration step is the exception, it mirrors the one-time,
sequential `etcdctl member add` step from `../manual/setup_etcd.sh`,
and only makes sense as part of first bringing the cluster up.

Passwords in `group_vars/all.yml` and `../manual/` are placeholders
(`changeme`). Override them (via `--extra-vars`, `group_vars`, or a
vault) rather than committing real credentials.
