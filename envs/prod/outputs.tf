output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "kubeconfig_command" {
  description = "Run this to configure kubectl."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "oidc_provider_arn" {
  description = "Use with the irsa module."
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "Use with the irsa module."
  value       = module.eks.oidc_provider_url
}

output "grafana_endpoint" {
  description = "Managed Grafana endpoint (input for envs/dev-dashboards)."
  value       = module.observability.grafana_endpoint
}

output "grafana_service_account_token" {
  description = "Short-lived Grafana token (input for envs/dev-dashboards). Treat as a secret."
  value       = module.observability.grafana_service_account_token
  sensitive   = true
}
