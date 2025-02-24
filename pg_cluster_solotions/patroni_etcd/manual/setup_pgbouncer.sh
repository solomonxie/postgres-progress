# ==== DON'T EXECUTE THIS SCRIPT DIRECTLY ====

# Install Pgbouncer
sudo apt install -y pgbouncer
sudo cp ./common_conf/pgbouncer.ini /etc/pgbouncer/pgbouncer.ini
sudo cp ./common_conf/pgbouncer_userlist.txt /etc/pgbouncer/userlist.txt
sudo cp ./common_conf/pgbouncer.service /lib/systemd/system/pgbouncer.service

sudo systemctl disable pgbouncer

sudo mkdir -p /var/log/pgbouncer
sudo chown postgres:postgres /var/log/pgbouncer

sudo systemctl enable pgbouncer
sudo systemctl start pgbouncer

# Test
ps aux |grep pgbouncer
sudo systemctl status pgbouncer
sudo netstat -tulnp |grep 6432
# >> tcp        0      0 0.0.0.0:6432            0.0.0.0:*               LISTEN      1719564/pgbouncer
telnet 0.0.0.0 6432
# Connected to 0.0.0.0.
# Escape character is '^]'.
sudo -u postgres psql -h 0.0.0.0 -p 6432 -U postgres
