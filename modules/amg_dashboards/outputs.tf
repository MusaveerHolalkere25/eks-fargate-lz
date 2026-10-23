output "cloudwatch_datasource_uid" {
  description = "UID of the CloudWatch data source created in Grafana."
  value       = grafana_data_source.cloudwatch.uid
}

output "dashboard_uid" {
  description = "UID of the EKS Fargate overview dashboard."
  value       = grafana_dashboard.eks_fargate_overview.uid
}
