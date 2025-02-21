#######################################################################
#                       DISREGARD THIS SOLUTION                       #
#######################################################################

# Install PgAdmin
source /opt/venv/bin/activate
pip install pgadmin4

# Configure pgAdmin (interactive email/password setup)
sudo cp ./pgadmin.service /etc/systemd/system/pgadmin.service
sudo mkdir -p /etc/pgadmin
cp ./pgadmin_conf.py /opt/venv/lib/python3.10/site-packages/pgadmin4/config.py
# sudo chmod 644 /etc/pgadmin/config_system.py
sudo mkdir -p /var/lib/pgadmin/ /var/log/pgadmin
sudo chown -R ec2-user:ec2-user /var/lib/pgadmin/
sudo chown -R ec2-user:ec2-user /var/log/pgadmin/

sudo systemctl daemon-reload
sudo systemctl enable pgadmin
sudo systemctl start pgadmin
sudo systemctl status pgadmin
sudo journalctl -u pgadmin -f
sudo tail -f /var/log/pgadmin/pgadmin4.log

# Add login user
sudo su postgres
source /opt/venv/bin/activate
pgadmin4-cli add-user 'pgadmin@example.com' 'pgadmin'
pgadmin4-cli get-users
# >>               User Details
# >> +---------------------------------------+
# >> | Field       | Value                   |
# >> |-------------+-------------------------|
# >> | Username    | pgadmin@example.com     |
# >> | Email       | pgadmin@example.com     |
# >> | auth_source | internal                |
# >> | role        | Non-admin               |
# >> | active      | True                    |
# >> +---------------------------------------+
