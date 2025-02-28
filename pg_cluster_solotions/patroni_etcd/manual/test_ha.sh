# Prerequisite(run these side by side of two nodes):
sudo systemctl status patroni
sudo systemctl status etcd
sudo systemctl status postgresql
sudo systemctl status pgbouncer
patronictl -c /etc/patroni.yml list
etcdctl endpoint status --cluster
sudo journalctl -u patroni -u etcd -u postgresql -u pgbouncer -f
sudo tail -f /var/log/pgbouncer/pgbouncer.log
# (Run this on HAproxy node)
sudo systemctl status haproxy
sudo journalctl -u haproxy -f
open http://node3.pg.internal:8080

# Create table for testing (Run this on primary):
psql -h localhost -p 5432 -U postgres app_db
psql>> CREATE TABLE test_ha (id SERIAL PRIMARY KEY, created_at TIMESTAMP DEFAULT now());
psql>> INSERT INTO test_ha DEFAULT VALUES;
psql>> INSERT INTO test_ha DEFAULT VALUES;
psql>> SELECT * FROM test_ha;


# Test continuous writing (run this on monitor node)
sudo su postgres
export PGPASSWORD=changeme
while true;do psql -h node3.pg.internal -p 5432 -U postgres -d app_db -c 'INSERT INTO test_ha DEFAULT VALUES;'; sleep 1; date; done;
# Test continuous reading (run this on monitor node in another shell)
while true;do psql -h node3.pg.internal -p 5432 -U postgres -d app_db -c 'SELECT * FROM test_ha ORDER BY id DESC LIMIT 1;'; sleep 1; done;



# Test data sync
sudo su postgres
# Run this on primary:
psql -h localhost -p 5432 -U postgres -c "CREATE ROLE role123;"
# Run this on replica:
psql -h localhost -p 5432 -U postgres -c "\du"
psql -h localhost -p 5432 -U postgres -c "DROP ROLE role123;"


# Test unavailable `Patroni`
sudo systemctl stop patroni
patronictl -c /etc/patroni.yml list
sudo systemctl start patroni
pgrep patroni |xargs sudo kill -9

# Test unavailable `etcd`
sudo systemctl stop etcd
etcdctl endpoint status --cluster
sudo systemctl start etcd
sudo systemctl status etcd
pgrep etcd |xargs sudo kill -9
sudo systemctl status etcd
etcdctl endpoint status --cluster

# Test unavailable `postgres` (will require full data restore)
sudo systemctl stop postgres
patronictl -c /etc/patroni.yml list
curl -I localhost:8008/primary
sudo systemctl start postgres
pgrep postgres |xargs sudo kill -9
patronictl -c /etc/patroni.yml list
curl -I localhost:8008/primary


# Test Disk full (create 10x 1GB files) -- repeat until disk is full
dd if=/dev/zero of=/tmp/test_disk_full bs=1G count=10 status=progress
df -h  # Check current disk remaining size
# or:
watch -n 1 df -h
rm /tmp/test_disk_full  # Clean testing files


# Test Network down
# sudo ip link set eth0 down  # Don't do this, it'll cut SSH too
# sudo ip link set eth0 up # Bring up network
sudo iptables -L
# watch -n 1 sudo iptables -L
# Add reject rules:
sudo iptables -A OUTPUT -p tcp --dport 5432 -j REJECT
sudo iptables -A INPUT -p tcp --dport 5432 -j REJECT
sudo iptables -A OUTPUT -p tcp --dport 6432 -j REJECT
sudo iptables -A INPUT -p tcp --dport 6432 -j REJECT
sudo iptables -A OUTPUT -p tcp --dport 2380 -j REJECT
sudo iptables -A INPUT -p tcp --dport 2380 -j REJECT
sudo iptables -A OUTPUT -p tcp --dport 2379 -j REJECT
sudo iptables -A INPUT -p tcp --dport 2379 -j REJECT
# Remove all reject rules:
sudo iptables -F
# Test:
nc -zv 0.0.0.0 5432
