# node3_conf

Per-node etcd config for node3, plus the HAProxy and pgAdmin setup that
run only on this node. node3 doesn't run PostgreSQL or Patroni itself,
it routes traffic to node1/node2 and hosts the admin UI. See
`../../README.md` for the setup order.
