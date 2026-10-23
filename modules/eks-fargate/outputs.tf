output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "API server endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_security_group_id" {
  description = "Cluster security group created by EKS."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider (used by the irsa module)."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  description = "OIDC issuer URL without the https:// prefix."
  value       = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

output "fargate_pod_execution_role_arn" {
  description = "IAM role used by Fargate to pull images and write logs."
  value       = aws_iam_role.fargate.arn
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data of the cluster (for the kubernetes provider)."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}
