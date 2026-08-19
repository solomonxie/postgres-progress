# node1_conf

Per-node etcd and Patroni config for node1. In this design node1 is the
first node: it initializes the etcd cluster and the Patroni cluster,
and the other nodes join it. See `../../README.md` for the setup order.
