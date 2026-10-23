# observability

Observability for an EKS cluster that runs only on Fargate.

- **Logs:** enables Fargate's built-in Fluent Bit. Creates the `aws-observability` namespace (with the required label), the `aws-logging` ConfigMap and the log group.
- **Metrics:** runs one ADOT collector (StatefulSet) that scrapes cAdvisor through the API server and publishes Container Insights metrics to CloudWatch (`ContainerInsights` namespace). Its IAM role is created with the `irsa` module and limited to this cluster's log groups and the `ContainerInsights` metric namespace.
- **Grafana:** an Amazon Managed Grafana workspace (service-managed permissions, CloudWatch data source), optional admin role association for IAM Identity Center users or groups, and a service account plus short-lived token for Terraform.

## Requirements

- The `kubernetes` provider must be configured by the caller against this cluster (see `envs/dev`).
- Call the module with `depends_on = [module.eks]` so Fargate profiles and CoreDNS exist before pods are scheduled.
- IAM Identity Center must be enabled if `grafana_authentication_providers` is `["AWS_SSO"]`.

## Notes

- `adot_image` is pinned. Check the tag exists in the public ECR gallery and bump it deliberately.
- Set `grafana_admin_user_ids` or `grafana_admin_group_ids`, or nobody can log in to the workspace.
- The service-account token is stored in Terraform state. Use a remote state backend with encryption and restricted access.
