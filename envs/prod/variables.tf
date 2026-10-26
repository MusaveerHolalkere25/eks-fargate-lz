variable "region" {
  description = "AWS region."
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "project" {
  description = "Project name used as a prefix."
  type        = string
  default     = "eks-fargate-lz"
}

variable "vpc_cidr" {
  description = "VPC CIDR. Must not overlap with other environments (dev uses 10.10.0.0/16)."
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use."
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3 (the VPC module carves /20 subnets for up to 3 AZs here)."
  }
}

variable "single_nat_gateway" {
  description = "Prod uses one NAT gateway per AZ so an AZ failure does not cut outbound access for the others."
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version. Check which versions EKS currently supports."
  type        = string
  default     = "1.33"
}

variable "api_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint. Must be specific ranges, never 0.0.0.0/0."
  type        = list(string)

  validation {
    condition     = length(var.api_access_cidrs) > 0 && !contains(var.api_access_cidrs, "0.0.0.0/0")
    error_message = "api_access_cidrs must contain at least one CIDR and must not contain 0.0.0.0/0 in prod."
  }
}

variable "cluster_log_retention_days" {
  description = "Retention of the EKS control plane log group."
  type        = number
  default     = 90
}

variable "observability_log_retention_days" {
  description = "Retention of Fargate application logs and Container Insights performance logs."
  type        = number
  default     = 30
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
