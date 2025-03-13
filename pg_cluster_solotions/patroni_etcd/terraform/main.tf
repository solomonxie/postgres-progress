data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  # node1, node2 run Postgres/Patroni/pgbouncer; node3 runs HAProxy + pgAdmin.
  # All three run etcd. See ../clustering_patroni_etcd/README.md.
  nodes = ["node1", "node2", "node3"]
}

resource "aws_instance" "node" {
  for_each = toset(local.nodes)

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.cluster.id
  vpc_security_group_ids = [aws_security_group.cluster.id]

  tags = {
    Name = "${var.cluster_name}-${each.key}"
  }
}

# Separate data volume for PostgreSQL, matching the /mnt/pg_data mount
# used by the setup scripts in ../clustering_patroni_etcd/.
resource "aws_ebs_volume" "pg_data" {
  for_each = toset(local.nodes)

  availability_zone = aws_instance.node[each.key].availability_zone
  size              = var.data_volume_size_gb
  type              = "gp3"

  tags = {
    Name = "${var.cluster_name}-${each.key}-pg-data"
  }
}

resource "aws_volume_attachment" "pg_data" {
  for_each = toset(local.nodes)

  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.pg_data[each.key].id
  instance_id = aws_instance.node[each.key].id
}
