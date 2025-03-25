# ==== DON'T EXECUTE THIS SCRIPT DIRECTLY ====

sudo apt install haproxy -y

sudo cp ./node3_conf/haproxy.cfg /etc/haproxy/haproxy.cfg


sudo systemctl stop haproxy
sudo systemctl enable haproxy
sudo systemctl start haproxy

# Test
sudo systemctl status haproxy
sudo journalctl -u haproxy -f

# Test Patroni's REST API with primary/replica :
# (run this on primary node)
curl -I localhost:8008/primary
# >> HTTP/1.0 200 OK
curl -I localhost:8008/replica
# >> HTTP/1.0 503 Service Unavailable

# Test network
nc -zv node3.pg.internal 5432  # Writer
# >> Connection to node3.pg.internal (10.0.1.13) 5432 port [tcp/bbs] succeeded!
nc -zv node3.pg.internal 6432  # Reader
# >> Connection to node3.pg.internal (10.0.1.13) 6432 port [tcp/bbs] succeeded!
for i in {1..30}; do echo $i; sleep 1; nc -zv node3.pg.internal 5432; done
# >> ^ Check out monitor UI: open http://node3.pg.internal:8080

# Test Write_backend:
# (run this on primary/replica node where `psql` command is available)
sudo -u postgres psql -h node3.pg.internal -p 5432 -U postgres -d postgres
postgres=# SELECT inet_server_addr(), inet_server_port();
# >> -[ RECORD 1 ]----+------------
# >> inet_server_addr | 10.0.1.11
# >> inet_server_port | 5432
postgres=# CREATE ROLE role_123;

# Test Read_backend:
sudo -u postgres psql -h node3.pg.internal -p 6432 -U postgres -d postgres
postgres=# SELECT inet_server_addr(), inet_server_port();
# >> -[ RECORD 1 ]----+------------
# >> inet_server_addr | 10.0.1.11
# >> inet_server_port | 5432
postgres=# SELECT pg_is_in_recovery();
# >> -[ RECORD 1 ]-----+--
# >> pg_is_in_recovery | t
postgres=# DROP ROLE role_123;
# >> ERROR:  cannot execute CREATE ROLE in a read-only transaction
