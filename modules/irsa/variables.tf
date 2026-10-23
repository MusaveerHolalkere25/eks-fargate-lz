variable "name" {
  description = "Name of the IAM role."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the cluster's IAM OIDC provider."
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC issuer URL without https://."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace of the service account."
  type        = string
}

variable "service_account" {
  description = "Kubernetes service account name allowed to assume the role."
  type        = string
}

variable "policy_arns" {
  description = "Map of name => managed policy ARN to attach."
  type        = map(string)
  default     = {}
}

variable "inline_policy_json" {
  description = "Optional least-privilege inline policy (JSON)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Extra tags applied to all resources."
  type        = map(string)
  default     = {}
}
