variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the cluster's IAM OIDC provider (IRSA)."
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC issuer URL without the https:// prefix."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the Fargate profile of the collector."
  type        = list(string)
}

variable "fargate_pod_execution_role_arn" {
  description = "Fargate pod execution role ARN (from the eks-fargate module)."
  type        = string
}

variable "adot_image" {
  description = "ADOT collector image. Pinned on purpose: verify the tag exists and bump it deliberately."
  type        = string
  default     = "public.ecr.aws/aws-observability/aws-otel-collector:v0.43.1"
}

variable "adot_cpu" {
  description = "CPU request and limit of the collector pod (must be a valid Fargate combination)."
  type        = string
  default     = "500m"
}

variable "adot_memory" {
  description = "Memory request and limit of the collector pod (must be a valid Fargate combination)."
  type        = string
  default     = "1Gi"
}

variable "log_retention_days" {
  description = "Retention in days for the Fargate application logs and Container Insights performance logs."
  type        = number
  default     = 14
}

variable "grafana_authentication_providers" {
  description = "Amazon Managed Grafana login providers. AWS_SSO needs IAM Identity Center enabled in the account."
  type        = list(string)
  default     = ["AWS_SSO"]
}

variable "grafana_admin_user_ids" {
  description = "IAM Identity Center user IDs that get the Grafana ADMIN role. Without any user or group, nobody can log in."
  type        = list(string)
  default     = []
}

variable "grafana_admin_group_ids" {
  description = "IAM Identity Center group IDs that get the Grafana ADMIN role."
  type        = list(string)
  default     = []
}

variable "grafana_token_ttl_seconds" {
  description = "Lifetime of the Terraform service-account token for Grafana (maximum 30 days)."
  type        = number
  default     = 2592000

  validation {
    condition     = var.grafana_token_ttl_seconds >= 1 && var.grafana_token_ttl_seconds <= 2592000
    error_message = "grafana_token_ttl_seconds must be between 1 and 2592000 (30 days)."
  }
}

variable "tags" {
  description = "Extra tags applied to AWS resources."
  type        = map(string)
  default     = {}
}
