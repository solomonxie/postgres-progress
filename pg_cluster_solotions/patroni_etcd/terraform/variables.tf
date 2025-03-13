variable "aws_region" {
  description = "AWS region to deploy the cluster into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the cluster VPC"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for each cluster node"
  type        = string
  default     = "t3.medium"
}

variable "data_volume_size_gb" {
  description = "Size (GB) of the EBS volume mounted for PostgreSQL data"
  type        = number
  default     = 8
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair for SSH access"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR range allowed to SSH into the nodes"
  type        = string
  default     = "0.0.0.0/0"
}

variable "cluster_name" {
  description = "Name prefix applied to all resources"
  type        = string
  default     = "pg-cluster-poc"
}
