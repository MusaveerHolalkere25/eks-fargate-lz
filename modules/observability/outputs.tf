output "grafana_endpoint" {
  description = "Amazon Managed Grafana workspace endpoint (no https:// prefix)."
  value       = aws_grafana_workspace.this.endpoint
}

output "grafana_workspace_id" {
  description = "Amazon Managed Grafana workspace ID."
  value       = aws_grafana_workspace.this.id
}

output "grafana_service_account_token" {
  description = "Short-lived Grafana service-account token for the dashboards stack. Treat as a secret."
  value       = aws_grafana_workspace_service_account_token.terraform.key
  sensitive   = true
}

output "adot_role_arn" {
  description = "IAM role assumed by the ADOT collector service account."
  value       = module.adot_irsa.role_arn
}

output "fargate_log_group_name" {
  description = "CloudWatch log group receiving Fargate pod logs."
  value       = aws_cloudwatch_log_group.fargate.name
}

output "performance_log_group_name" {
  description = "CloudWatch log group receiving Container Insights performance events."
  value       = aws_cloudwatch_log_group.performance.name
}
