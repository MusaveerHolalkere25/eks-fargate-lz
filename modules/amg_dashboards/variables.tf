variable "region" {
  description = "AWS region used as the default region of the CloudWatch data source."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name whose Container Insights metrics are shown."
  type        = string
}

variable "cloudwatch_datasource_name" {
  description = "Name of the CloudWatch data source in Grafana. Defaults to \"CloudWatch <region>\"."
  type        = string
  default     = null
}
