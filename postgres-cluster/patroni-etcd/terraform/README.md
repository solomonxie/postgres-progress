# Terraform: Patroni Cluster Example

This provisions the AWS infrastructure for the 3-node Patroni/etcd
cluster described in `../README.md`. It creates the EC2 instances,
networking, and disks; it does not install or configure PostgreSQL,
Patroni, or etcd. Once the instances exist, use `../ansible/` (or the
manual steps in `../manual/`) to install and configure the cluster
software.

## Files

File order on disk doesn't matter — Terraform resolves the build order
from the resource references between files. This is that order:

```
terraform apply
  ├─ versions.tf   → provider "aws" setup
  ├─ variables.tf  → resolve inputs (region, key pair, CIDR ranges, etc.)
  ├─ network.tf    → VPC, subnet, route table, security group
  ├─ ec2.tf        → 3 EC2 instances (node1-3) + a PostgreSQL data EBS volume each,
  │                  built off network.tf's subnet/security group
  └─ outputs.tf    → instance IDs and private IPs
        │
        ▼
fill in ../ansible/inventory/hosts.ini with the private IPs
        │
        ▼
ansible-playbook -i inventory/hosts.ini site.yml   (installs and configures the cluster)
```

## Usage

    terraform init
    terraform plan -var="key_pair_name=your-key"
    terraform apply -var="key_pair_name=your-key"

After apply, take the private IPs from `terraform output` and use them
to fill in the placeholder addresses (`10.0.1.11`, `10.0.1.12`,
`10.0.1.13`) in `../manual/node1_conf/`, `../manual/node2_conf/`,
`../manual/node3_conf/`, and `../ansible/inventory/hosts.ini`.

To tear everything down:

    terraform destroy

## Notes

This is a minimal example for trying out the cluster design, not a
production module. It has no remote state backend, no multi-AZ
placement, and no automated failover of the infrastructure layer itself
(that's what Patroni and etcd are for). Review instance sizing and the
security group rules before using this anywhere but a sandbox account.
