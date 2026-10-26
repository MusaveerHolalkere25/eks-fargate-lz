variable "region" {
  description = "AWS region of the Grafana workspace."
  type        = string
  default     = "eu-west-1"
}

variable "project" {
  description = "Project name prefix (must match envs/dev)."
  type        = string
  default     = "eks-fargate-lz"
}

variable "environment" {
  description = "Environment name (must match envs/dev)."
  type        = string
  default     = "prod"
}

variable "grafana_endpoint" {
  description = "Managed Grafana endpoint without https:// (output grafana_endpoint of envs/dev)."
  type        = string
}

variable "grafana_auth" {
  description = "Grafana service-account token (output grafana_service_account_token of envs/dev)."
  type        = string
  sensitive   = true
}
