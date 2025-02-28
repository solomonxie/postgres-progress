# ==== DON'T EXECUTE THIS SCRIPT DIRECTLY ====

# etcd needs real IP address:
# node1=10.0.1.11, node2=10.0.1.12

sudo systemctl stop etcd
nc -l 2380

telnet node1.pg.internal 2380
telnet node2.pg.internal 2380

sudo systemctl start etcd

# Test sending key:
export ETCDCTL_API=3
etcdctl --endpoints=http://node1.pg.internal:2379 put test_key111 test_value111
# OK

etcdctl --endpoints=http://node2.pg.internal:2379 put test_key111 test_value111
# OK

# Test receiving key (from another machine)
etcdctl --endpoints=http://node1.pg.internal:2379 get test_key
etcdctl --endpoints=http://node2.pg.internal:2379 get test_key111

# Test cluster health
etcdctl --endpoints=http://node1.pg.internal:2379 endpoint health
etcdctl --endpoints=http://node2.pg.internal:2379 endpoint health
