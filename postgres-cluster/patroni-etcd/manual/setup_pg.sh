# ==== DON'T EXECUTE THIS SCRIPT DIRECTLY ====

# Install PG (on all nodes, including monitor node, because we need to test connection from watcher node)
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update
sudo apt install -y postgresql-17 postgresql-client-17 postgresql-server-dev-17

ls /usr/lib/postgresql/17/bin/  # Test folder existence
echo 'export PATH="/usr/lib/postgresql/17/bin/:$PATH"' >> ~/.bashrc

# Disable PG server completely (later will be entirely managed by Patroni)
sudo systemctl stop postgresql
sudo systemctl disable postgresql
sudo rm /etc/init.d/postgresql
sudo rm /lib/systemd/system/postgresql.service
sudo rm /lib/systemd/system/postgresql@.service
sudo systemctl daemon-reload
sudo systemctl status postgresql |cat
ps aux |grep postgres


#######################################################################
#                 BELOW IS FOR STANDALONE PG SERVER,                  #
#                 DISABLE IF USE PATRONI TO MANAGE                    #
#######################################################################

# Init PG server
sudo systemctl enable postgresql
sudo systemctl start postgresql
ps aux |grep postgres

# Configure pg
ls /etc/postgresql/17/main/  # Test folder existence
sudo cp ./common_conf/postgresql.conf /etc/postgresql/17/main/postgresql.conf
sudo cp ./common_conf/pg_hba.conf /etc/postgresql/17/main/pg_hba.conf

# Prepare dynamic config for Patroni (it will save dynamic configs here)
sudo chown postgres:postgres /mnt/pg_data/data/

# REF: https://www.postgresql.org/docs/current/libpq-pgpass.html
# Configure pgpass
cp ./common_conf/pgpass.conf /tmp/pgpass0
chmod 600 /tmp/pgpass0
echo 'export PGPASSFILE=/tmp/pgpass0' >> ~/.bashrc
source ~/.bashrc

# Reload and test
sudo systemctl restart postgresql@17-main
sudo systemctl status postgresql@17-main
sudo netstat -tulnp |grep 5432
# sudo journalctl -u postgresql@17-main -f  # check error logs if failed

sudo tail -f /var/log/postgresql/*.log


# In case of error `Can't open PID file /run/postgresql/17-main.pid (yet?) after start: Operation not permitted`
# Test in debug mode:
sudo -u postgres /usr/lib/postgresql/17/bin/postgres -D /mnt/pg_data/data -c config_file=/etc/postgresql/17/main/postgresql.conf
# Change permission:
sudo chown -R postgres:postgres /mnt/pg_data/data
sudo chmod 700 /mnt/pg_data/data
# Restart:
sudo systemctl restart postgresql
