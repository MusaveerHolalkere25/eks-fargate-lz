variable "region" {
  description = "AWS region."
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name used as a prefix."
  type        = string
  default     = "eks-fargate-lz"
}

variable "vpc_cidr" {
  description = "VPC CIDR."
  type        = string
  default     = "10.10.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use."
  type        = number
  default     = 2
}

variable "single_nat_gateway" {
  description = "One shared NAT gateway (dev) vs one per AZ (prod)."
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version. Check which versions EKS currently supports."
  type        = string
  default     = "1.33"
}

variable "api_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint. Set to your own IP, e.g. [\"203.0.113.10/32\"]."
  type        = list(string)
}

variable "grafana_admin_user_ids" {
  description = "IAM Identity Center user IDs that get the Grafana ADMIN role (needed to log in to Grafana)."
  type        = list(string)
  default     = []
}

variable "grafana_admin_group_ids" {
  description = "IAM Identity Center group IDs that get the Grafana ADMIN role."
  type        = list(string)
  default     = []
}
