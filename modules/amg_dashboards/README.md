# amg_dashboards

Creates a CloudWatch data source (workspace role authentication) and an **EKS Fargate overview** dashboard in Grafana. The dashboard is defined in `main.tf` and queries the metrics published by the `observability` module: pod CPU and memory utilization over limit and network throughput, by namespace and by pod.

The Grafana provider must be configured by the caller with the workspace URL and a service-account token (see `envs/dev-dashboards`).
