# ==== DON'T EXECUTE THIS SCRIPT DIRECTLY ====

# Stop native postgresql.service(systemd),
# because Patroni will fully control the server processes
sudo systemctl stop postgresql
sudo systemctl disable postgresql

# Install Patroni (require Python3)
source /opt/venv/bin/activate
pip install patroni[etcd] psycopg2-binary

# Configure Patroni
sudo cp ./common_conf/patroni.service /etc/systemd/system/patroni.service
sudo cp ./node1_conf/patroni.yml /etc/patroni.yml
sudo cp ./common_conf/patroni_callback.py /etc/patroni_callback.py
sudo cp ./common_conf/patroni.env /etc/patroni.env
sudo chmod 644 /etc/patroni.env
sudo chmod 644 /etc/postgresql/pgpass0

# Configure roles
sudo -u postgres PGPASSWORD=changeme psql -h localhost -p 5432 -U postgres -c "ALTER ROLE replicator WITH REPLICATION LOGIN;"

# Test config file
sudo /opt/venv/bin//patroni --validate-config /etc/patroni.yml # --ignore-listen-port
# >> restapi.listen 0.0.0.0:8008 didn't pass validation: Port 8008 is already in use.
# >> postgresql.listen 0.0.0.0:5432 didn't pass validation: Port 5432 is already in use.

# Test PG users (on primary node)
sudo -u postgres PGPASSWORD=changeme psql -h localhost -p 5432 -U postgres -c "\du+ postgres"
sudo -u postgres PGPASSWORD=changeme psql -h localhost -p 5432 -U replicator -c "\du+ replicator"
sudo -u postgres PGPASSWORD=changeme psql -h localhost -p 5432 -U rewind_user -c "\du+ rewind_user"
# If not working ^, run below on primary node (see ../../../aws_rds_to_pg17/roles_example.sql for the pattern):
# cp ./roles.sql /tmp/roles.sql
# sudo chmod 644 /tmp/roles.sql
# sudo -u postgres PGPASSWORD=changeme psql -h localhost -p 5432 -U postgres -f /tmp/roles.sql

# Test Patroni's REST API with primary/replica (run this on primary node):
curl -I localhost:8008/primary
# >> HTTP/1.0 200 OK
curl -I localhost:8008/replica
# >> HTTP/1.0 503 Service Unavailable


# Start Patroni service
sudo systemctl daemon-reload
sudo systemctl enable patroni
sudo systemctl start patroni
ps aux |grep patroni
sudo systemctl status patroni
sudo journalctl -u patroni -f

# Test cluster
patronictl -c /etc/patroni.yml list
# >> + Cluster: cluster1 (7472932048542519318) -+-----------+-----------------+---------------------------+
# >> | Member   | Host       | Role   | State   | TL | Lag in MB | Pending restart | Pending restart reason    |
# >> +----------+------------+--------+---------+----+-----------+-----------------+---------------------------+
# >> |  node1   | 10.0.1.11  | Leader | running |  6 |           | *               | max_connections: 200->100 |
# >> +----------+------------+--------+---------+----+-----------+-----------------+---------------------------+
curl -v '0.0.0.0:8008'
# >> {"state": "running", "postmaster_start_time": "2025-02-28 02:00:18.879888+00:00", "role": "primary", "server_version": 170003, "xlog": {"location": 2846826000}, "timeline": 6, "dcs_last_seen": 1740726146, "database_system_identifier": "7472932048542519318", "pending_restart": true, "pending_restart_reason": {"max_connections": {"old_value": "200", "new_value": "100"}}, "patroni": {"version": "4.0.4", "scope": "cluster1", "name": "node1"}}
patronictl -c /etc/patroni.yml show-config
# >> ....


#######################################################################
#                          MANUAL FIX ISSUES                          #
#######################################################################

# In case of error ` Can't start; there is already a node named 'node2' running`
sudo vim /etc/patroni.yml  # Check if the IP address and replica settings is node2's
sudo systemctl restart patroni
sudo journalctl -u patroni -f
patronictl -c /etc/patroni.yml list
# >>...

# In case of error `system ID mismatch, node node2 belongs to a different cluster...`
# or `no pg_hba.conf entry for host "[local]", user "postgres", database "template1", no encryption`
patronictl -c /etc/patroni.yml list
patronictl -c /etc/patroni.yml edit-config  # Check global settings
sudo cat /etc/postgresql/17/main/pg_hba.conf  # Compare global settings with local settings
sudo systemctl restart patroni
patronictl -c /etc/patroni.yml reinit cluster1 node2

# In case of error `no pg_hba.conf entry for host "[local]", user "postgres", database "template1", no encryption`
# ...

# patronictl -c /etc/patroni.yml list
# patronictl -c /etc/patroni.yml edit-config  # Check global settings
# sudo cat /etc/postgresql/17/main/pg_hba.conf  # Compare global settings with local settings
# sudo systemctl restart patroni
# patronictl -c /etc/patroni.yml reinit cluster1 node2


# In case of error `system ID mismatch, node node2 belongs to a different cluster: 7472932048542519318 != 7472941754500255417`
sudo systemctl stop patroni
sudo mv /mnt/pg_data/data /mnt/pg_data/data_bak  # Remove all data from this node
# Pull all data from primary node:
sudo -u postgres pg_basebackup -h 10.0.1.11 -D /mnt/pg_data/data -U replicator -P -R
sudo systemctl start patroni

# In case of error `lock file "postmaster.pid" is empty HINT:  Either another server is starting, or the lock file is the remnant of a previous server startup crash.`
sudo systemctl stop patroni
pgrep postgres|xargs sudo kill -9  # kill all stale processes
sudo systemctl start patroni


# How to switch back the primary when it's back online:
patronictl -c /etc/patroni.yml switchover
# >> Current cluster topology
# >> + Cluster: cluster1 (7472932048542519318) ---+-----------+
# >> | Member   | Host       | Role    | State     | TL | Lag in MB |
# >> +----------+------------+---------+-----------+----+-----------+
# >> |  node1   | 10.0.1.11  | Replica | streaming |  9 |         0 |
# >> |  node2   | 10.0.1.12  | Leader  | running   |  9 |           |
# >> +----------+------------+---------+-----------+----+-----------+
# >> Primary [node2]: node2
# >> Candidate ['node1'] []: node1
# >> When should the switchover take place (e.g. 2025-02-28T23:43 )  [now]: now
# >> Are you sure you want to switchover cluster cluster1, demoting current leader node2? [y/N]: y
# >> 2025-02-28 22:43:55.80925 Successfully switched over to "node1"

# If failed server cannot restart postgresql/patroni:
sudo mv /mnt/pg_data/data /mnt/pg_data/data_bak  # Remove all data from this node
sudo -u postgres pg_basebackup -h 10.0.1.12 -D /mnt/pg_data/data -U replicator -P -R --wal-method=stream
sudo systemctl start patroni  # Make sure patroni runs first to join patroni cluster
patronictl -c /etc/patroni.yml reinit cluster1 node1  # reinit all pg config files
# >> Are you sure you want to reinitialize members node1? [y/N]: y
# >> Success: reinitialize for member node1
patronictl -c /etc/patroni.yml list
# >> + Cluster: cluster1 (7472932048542519318) ----+-----------+-----------------+---------------------------+
# >> | Member   | Host       | Role    | State     | TL | Lag in MB | Pending restart | Pending restart reason    |
# >> +----------+------------+---------+-----------+----+-----------+-----------------+---------------------------+
# >> |  node1   | 10.0.1.11  | Replica | streaming |  7 |         0 | *               | max_connections: 200->100 |
# >> |  node2   | 10.0.1.12  | Leader  | running   |  7 |           | *               | max_connections: 200->100 |
# >> +----------+------------+---------+-----------+----+-----------+-----------------+---------------------------+
# ^ Primary shows "running" and replica shows "streaming" is the expected healthy status.
# ^ If both are running, then something is wrong with replica.
ps aux |grep postg|grep bin
# postgres ... /usr/lib/postgresql/17/bin/postgres -D /mnt/pg_data/data --config-file=/etc/postgresql/17/main/postgresql.conf ...

# Or manually start pg server
sudo -u postgres /usr/lib/postgresql/17/bin/postgres -D /etc/postgresql/17/main


# What to do after restart/stop a patroni/pg server?
# There may be failure when restarting a stopped server (patroni or pg)
patronictl -c /etc/patroni.yml reinit cluster1 node2  # `reinit` will wipe out the data entirely and fetch all data from leader
# >> Are you sure you want to reinitialize members node2? [y/N]: y
# >> Success: reinitialize for member node2
patronictl -c /etc/patroni.yml list

# What's the right way to restart patroni/pg?
patronictl -c /etc/patroni.yml pause
systemctl restart patroni
patronictl -c /etc/patroni.yml resume


# In case of `could not start WAL streaming: ERROR: requested timeline 17 is not in this server's history`
#>> | Member   | Host       | Role    | State   | TL | Lag in MB |
#>> +----------+------------+---------+---------+----+-----------+
#>> | node1 | 10.0.1.11  | Leader  | running | 17 |           |
#>> | node2 | 10.0.1.12  | Replica | running | 16 |         0 |
#>> +----------+------------+---------+---------+----+-----------+
# Option1: reinit (will wipe out all data and fetch fresh data from primary)
patronictl -c /etc/patroni.yml reinit cluster1 node1
# Option2: rewind (doesn't work because the config is managed by patroni)
# sudo -u postgres /usr/lib/postgresql/17/bin/pg_rewind --target-pgdata=/mnt/pg_data/data --source-server="host=10.0.1.11 user=replicator dbname=postgres"
# Option3: manually copy the WAL timeline/history to node2 (caution!)
# rsync -avz --delete /mnt/pg_data/data/pg_wal/ postgres@10.0.1.12:/mnt/pg_data/data/pg_wal/


# How to restart a node in the cluster
patronictl -c /etc/patroni.yml restart cluster1 node1


# How to remove a cluster and start from zero (not working)
# patronictl -c /etc/patroni.yml remove cluster1
# >> Please confirm the cluster name to remove: cluster1
# >> You are about to remove all information in DCS for cluster1, please type: "Yes I am aware": Yes I am aware
# >> This cluster currently is healthy. Please specify the leader name to continue: node1

# How to remove a cluster and start from zero
sudo systemctl stop patroni  # (do this on every node)
sudo rm -rf /mnt/pg_data/data  # remove all data
sudo systemctl start patroni


# How to check out etcd stored configs or leader informations (Patroni stores through etcd V2 API, can't be seen by V3 API)
ETCDCTL_API=2 etcdctl ls /pg-cluster/cluster1/
# >> /pg-cluster/cluster1/members
# >> /pg-cluster/cluster1/initialize
# >> /pg-cluster/cluster1/leader
# >> /pg-cluster/cluster1/config
# >> /pg-cluster/cluster1/status
# >> /pg-cluster/cluster1/history
ETCDCTL_API=2 etcdctl get /pg-cluster/cluster1/leader
ETCDCTL_API=2 etcdctl ls /pg-cluster/cluster1/members
ETCDCTL_API=2 etcdctl get /pg-cluster/cluster1/members/node1
# >> {"conn_url":"postgres://10.0.1.11:5432/postgres","api_url":"http://10.0.1.11:8008/patroni","state":"running","role":"primary","version":"4.0.4","xlog_location":50350600,"timeline":9}
# OR, just simply use REST API. REF: https://etcd.io/docs/v2.3/members_api/
curl http://127.0.0.1:2379/v2/members |jq
# >> {"members":[{"id":"ba5ed0f1c8d1438d","name":"node3","peerURLs":["http://10.0.1.13:2380"],"clientURLs":["http://10.0.1.13:2379"]},{"id":"bfbab8d5dc69c979","name":"node1","peerURLs":["http://10.0.1.11:2380"],"clientURLs":["http://10.0.1.11:2379"]},{"id":"fb08b14e36806659","name":"node2","peerURLs":["http://10.0.1.12:2380"],"clientURLs":["http://10.0.1.12:2379"]}]}
curl -s http://127.0.0.1:2379/v2/keys/pg-cluster/cluster1/members/node1 |jq  # Check out a specific Key
# >> {"action":"get","node":{"key":"/pg-cluster/cluster1/members/node1","value":"{\"conn_url\":\"postgres://10.0.1.11:5432/postgres\",\"api_url\":\"http://10.0.1.11:8008/patroni\",\"state\":\"running\",\"role\":\"primary\",\"version\":\"4.0.4\",\"xlog_location\":50350600,\"timeline\":9}","expiration":"2025-03-03T23:13:54.772966779Z","ttl":28,"modifiedIndex":321,"createdIndex":321}}
curl -s http://127.0.0.1:2379/v2/keys/pg-cluster/cluster1/config |jq '.node.value |fromjson |.postgresql.pg_hba'
# >> [ "local all postgres md5", "local all all peer", "host all all 0.0.0.0/0 md5", "host replication replicator 0.0.0.0/0 md5", "host replication rewind_user 0.0.0.0/0 md5" ]


#######################################################################
#                       TEST FAILURE SCENARIOS                        #
#######################################################################

# REF: https://patroni.readthedocs.io/en/latest/README.html#testing-your-ha-solution
# > "One thing that you should not do is run kill -9 on a postmaster process.
# > This is because doing so does not mimic any real life scenario.
# > If you are concerned your infrastructure is insecure and an attacker could run kill -9,
# > no amount of HA process is going to fix that.
# > The attacker will simply kill the process again, or cause chaos in another way."
