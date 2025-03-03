output "node_private_ips" {
  description = "Private IPs for each node, use these to fill in patroni.yml / etcd.conf.yml"
  value       = { for k, v in aws_instance.node : k => v.private_ip }
}

output "node_public_ips" {
  description = "Public IPs for SSH access"
  value       = { for k, v in aws_instance.node : k => v.public_ip }
}

output "node_instance_ids" {
  value = { for k, v in aws_instance.node : k => v.id }
}
