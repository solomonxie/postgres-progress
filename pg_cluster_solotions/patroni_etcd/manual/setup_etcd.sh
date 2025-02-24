# ==== DON'T EXECUTE THIS SCRIPT DIRECTLY ====,

# <About etcd's `Quorum/Consensus` Principal (Raft algorithm)>
# If there are 3 running nodes, it can form a quorum/consensus on who's leader
# If there are 2 nodes, 1 down and 1 running, etcd will REFUSE to read/write any data

# <How Does Patroni Use Etcd to Choose Leader?>
#

# Install etcd
sudo apt install -y etcd

# Configure
sudo cp ./common_conf/etcd.service /etc/systemd/system/etcd2.service
sudo cp ./node1_conf/etcd.conf.yml /etc/etcd.conf.yml
sudo mv /etc/default/etcd /tmp/backup_etcd.env  # Make sure no dirty conflict confs

# Run
sudo systemctl enable etcd
sudo systemctl start etcd
ps aux |grep etcd
sudo systemctl status etcd
sudo journalctl -u etcd -f
sudo systemctl restart etcd

export ETCDCTL_API=3
echo 'export ETCDCTL_API=3' >> ~/.bashrc  # Enable `etcdctl get --prefix ''`

# Add each node: node2
etcdctl member list
# >> 32cfc508d044762e, started, node1, http://10.0.1.11:2380, http://10.0.1.11:2379
etcdctl member add node2 --peer-urls=http://10.0.1.12:2380
# >> Member e9a76466451a3f70 added to cluster 3e69de08dfefb417
# >> ETCD_NAME="node2"
# >> ETCD_INITIAL_CLUSTER="node1=http://10.0.1.11:2380,node2=http://10.0.1.12:2380"
# >> ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.0.1.12:2380"
# >> ETCD_INITIAL_CLUSTER_STATE="existing"
etcdctl member list
# >> bfbab8d5dc69c979, started, node1, http://10.0.1.11:2380, http://10.0.1.11:2379
# >> d2c73341ffebbd51, unstarted, , http://10.0.1.12:2380,

# Go to node2's shell:
sudo systemctl restart etcd

# Test
# REF: https://etcd.io/docs/v3.4/dev-guide/interacting_v3/
etcdctl endpoint health
curl -L http://0.0.0.0:2379/health
# >> {"health":"true"}
# Show each node status in the cluster:
etcdctl endpoint status --cluster
# >> http://10.0.1.11:2379, bfbab8d5dc69c979, 3.3.25, 20 kB, true, 26, 7
# >> http://10.0.1.12:2379, d2c73341ffebbd51, 3.3.25, 20 kB, false, 26, 7
# ^^^ "true/false" means "is_leader"
# Show all members (regardless if node is alive/dead)
etcdctl member list
# Test write and read
etcdctl put /test/abc 123
etcdctl put /test/def 456
etcdctl get /test/abc --print-value-only
# >> 123
etcdctl get --prefix ''
# >> /test/abc
# >> 123
# >> /test/def
# >> 456


# In case of error `request cluster ID mismatch (got ... want ...)`
sudo systemctl stop etcd
sudo rm -rdf /var/lib/etcd/* /var/lib/etcd/default
sudo systemctl start etcd


# How to reset the cluster and start over again from step0 (run on all nodes):
sudo systemctl stop etcd
sudo systemctl disable etcd
sudo rm -rf /var/lib/etcd/node
sudo ls /var/lib/etcd/
sudo systemctl enable etcd
sudo systemctl start etcd
# Edit the config files..
# ...
# Manually add members from node1 (refer to above commands)
# ... (node1 only)...
etcdctl endpoint health
# >> 127.0.0.1:2379 is healthy: successfully committed proposal: took = 1.678307ms


# In case of new node won't join existing cluster, remove data directory
sudo systemctl stop etcd
sudo rm -rf /var/lib/etcd/node
sudo ls /var/lib/etcd/  # Make sure no any file is left
sudo systemctl start etcd
etcdctl member list


# How to force change leader
etcdctl endpoint status --cluster  # Check who's leader
# >> http://10.0.1.13:2379, 28be2e9214054ea0, 3.3.25, 20 kB, false, 284, 718952
# >> http://10.0.1.11:2379, bfbab8d5dc69c979, 3.3.25, 20 kB, false, 284, 718956
# >> http://10.0.1.12:2379, d2c73341ffebbd51, 3.3.25, 20 kB, true, 284, 718958
sudo systemctl stop etcd  # Run this on each future-follower node
sudo systemctl start etcd  # Run this on each stopped node after leader is chosen


# How to read/write key/values set by Patroni
# Patroni uses etcd V2 API, so:
ETCDCTL_API=2 etcdctl ls /pg-cluster/cluster1
# >> /pg-cluster/cluster1/failover
# >> /pg-cluster/cluster1/history
# >> /pg-cluster/cluster1/initialize
# >> /pg-cluster/cluster1/leader
# >> /pg-cluster/cluster1/members
# >> /pg-cluster/cluster1/status
# >> /pg-cluster/cluster1/config
# Remove the cluster:
# ETCDCTL_API=2 etcdctl rm /pg-cluster/cluster1/failover
# ETCDCTL_API=2 etcdctl rm /pg-cluster/cluster1/history
# # ETCDCTL_API=2 etcdctl rm /pg-cluster/cluster1/...
# ETCDCTL_API=2 etcdctl rmdir /pg-cluster/cluster1
# Or:
# sudo rm -rf /var/lib/etcd/node
