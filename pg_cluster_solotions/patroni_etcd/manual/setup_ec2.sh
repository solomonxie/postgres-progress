# ==== DON'T EXECUTE THIS SCRIPT DIRECTLY ====

# ssh ec2-user@node1.pg.internal

sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget gnupg2 lsb-release software-properties-common

# Install Python
sudo apt install -y python3-pip python3-venv python3-virtualenv
sudo mkdir /opt/venv
sudo chown ec2-user:ec2-user /opt/venv
virtualenv -p python3 /opt/venv
source /opt/venv/bin/activate

echo 'export PATH="/opt/venv/bin/:$PATH"' >> ~/.bashrc
source ~/.bashrc

# ==Attach EBS==
lsblk  # List block devices and find the EBS location
sudo mkfs -t ext4 /dev/nvme1n1  # Format volume
sudo mkdir -p /mnt/pg_data  # Create folder for mounting
sudo mount /dev/nvme1n1 /mnt/pg_data  # Mount volume
sudo chown -R postgres:postgres /mnt/pg_data  # Grand PG permission
sudo chmod 700 /mnt/pg_data
sudo blkid /dev/nvme1n1  # Auto mount on boot
echo "/dev/nvme0n1 /mnt/pg_data ext4 defaults,auto,noatime,nodiratime,noexec,relatime 0 0" >> /etc/fstab
sudo mount -a  # Apply changes of /etc/fstab



# Test all ports
nc -zv 0.0.0.0 5432
nc -zv 0.0.0.0 6432
nc -zv 0.0.0.0 2379
nc -zv 0.0.0.0 2380
nc -zv 0.0.0.0 8008

# Test peer network
nc -zv node1.pg.internal 5432
nc -zv node2.pg.internal 5432
nc -zv node3.pg.internal 5432
