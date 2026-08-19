# PostgreSQL Cluster Solutions

Different ways to run a self-managed, highly-available PostgreSQL
cluster: same 3-node shape (two PostgreSQL nodes plus a routing node),
different distributed configuration store (DCS) underneath Patroni.

- `patroni_etcd/`: Patroni with etcd as the DCS. The full reference
  design, with configs, setup scripts, Terraform, and tests.

Start with `patroni_etcd/README.md`, it has the full design diagram
and setup walkthrough. `patroni_zookeeper/` only documents its diff
from that baseline.
