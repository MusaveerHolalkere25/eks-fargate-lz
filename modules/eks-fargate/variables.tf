variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version. Check the versions currently supported by EKS."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the control plane ENIs and Fargate pods."
  type        = list(string)
}

variable "fargate_namespaces" {
  description = "Namespaces that get a Fargate profile. kube-system is required for CoreDNS."
  type        = set(string)
  default     = ["kube-system", "default"]
}

variable "endpoint_public_access" {
  description = "Expose the API server publicly (restrict with public_access_cidrs)."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint. Set this to your own IP range."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_log_types" {
  description = "Control plane log types sent to CloudWatch."
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

variable "log_retention_days" {
  description = "Retention of the control plane log group."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Extra tags applied to all resources."
  type        = map(string)
  default     = {}
}
