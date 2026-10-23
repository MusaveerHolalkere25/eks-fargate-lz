locals {
  logging_namespace  = "aws-observability"
  insights_namespace = "fargate-container-insights"
  adot_sa_name       = "adot-collector"
  adot_labels = {
    app       = "aws-adot"
    component = "adot-collector"
  }
}

# -------------------------------------------------------------------
# Log groups (managed here so retention is set and logs do not pile up)
# -------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "fargate" {
  name              = "/aws/eks/${var.cluster_name}/fargate-logs"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "performance" {
  name              = "/aws/containerinsights/${var.cluster_name}/performance"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# -------------------------------------------------------------------
# Fargate log routing (built-in Fluent Bit).
# The namespace MUST carry the label aws-observability=enabled and the
# ConfigMap MUST be named aws-logging.
# -------------------------------------------------------------------
resource "kubernetes_namespace_v1" "logging" {
  metadata {
    name = local.logging_namespace
    labels = {
      "aws-observability" = "enabled"
    }
  }
}

resource "kubernetes_config_map_v1" "aws_logging" {
  metadata {
    name      = "aws-logging"
    namespace = kubernetes_namespace_v1.logging.metadata[0].name
  }

  data = {
    "output.conf" = <<-EOT
      [OUTPUT]
          Name                cloudwatch_logs
          Match               *
          region              ${var.region}
          log_group_name      ${aws_cloudwatch_log_group.fargate.name}
          log_stream_prefix   fargate-
          auto_create_group   false
    EOT

    "filters.conf" = <<-EOT
      [FILTER]
          Name                kubernetes
          Match               kube.*
          Merge_Log           On
          Keep_Log            Off
          Buffer_Size         0
          Kube_Meta_Cache_TTL 300s
    EOT
  }
}

# -------------------------------------------------------------------
# Container Insights metrics: ADOT collector on Fargate (IRSA, least privilege)
# -------------------------------------------------------------------
resource "kubernetes_namespace_v1" "insights" {
  metadata {
    name = local.insights_namespace
  }
}

resource "aws_eks_fargate_profile" "insights" {
  cluster_name           = var.cluster_name
  fargate_profile_name   = "${var.cluster_name}-container-insights"
  pod_execution_role_arn = var.fargate_pod_execution_role_arn
  subnet_ids             = var.private_subnet_ids

  selector {
    namespace = local.insights_namespace
  }

  tags = var.tags
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "adot" {
  statement {
    sid = "WriteContainerInsightsLogs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/containerinsights/${var.cluster_name}/*",
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/containerinsights/${var.cluster_name}/*:*",
    ]
  }

  statement {
    sid       = "DescribeLogGroups"
    actions   = ["logs:DescribeLogGroups"]
    resources = ["*"]
  }

  statement {
    sid       = "PutContainerInsightsMetrics"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["ContainerInsights"]
    }
  }
}

module "adot_irsa" {
  source = "../irsa"

  name               = "${var.cluster_name}-adot"
  oidc_provider_arn  = var.oidc_provider_arn
  oidc_provider_url  = var.oidc_provider_url
  namespace          = local.insights_namespace
  service_account    = local.adot_sa_name
  inline_policy_json = data.aws_iam_policy_document.adot.json
  tags               = var.tags
}

resource "kubernetes_service_account_v1" "adot" {
  metadata {
    name      = local.adot_sa_name
    namespace = kubernetes_namespace_v1.insights.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.adot_irsa.role_arn
    }
  }
}

resource "kubernetes_cluster_role_v1" "adot" {
  metadata {
    name = "${var.cluster_name}-adot-collector"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "nodes/proxy", "nodes/metrics", "services", "endpoints", "pods"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    non_resource_urls = ["/metrics/cadvisor"]
    verbs             = ["get"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "adot" {
  metadata {
    name = "${var.cluster_name}-adot-collector"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.adot.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.adot.metadata[0].name
    namespace = kubernetes_namespace_v1.insights.metadata[0].name
  }
}

resource "kubernetes_config_map_v1" "adot" {
  metadata {
    name      = "adot-collector-config"
    namespace = kubernetes_namespace_v1.insights.metadata[0].name
  }

  data = {
    "adot-collector.yaml" = templatefile("${path.module}/adot-collector.yaml.tpl", {
      region      = var.region
      ClusterName = var.cluster_name
    })
  }
}

resource "kubernetes_service_v1" "adot" {
  metadata {
    name      = "adot-collector"
    namespace = kubernetes_namespace_v1.insights.metadata[0].name
  }

  spec {
    cluster_ip = "None"
    selector   = local.adot_labels

    port {
      name        = "telemetry"
      port        = 8888
      target_port = 8888
    }
  }
}

resource "kubernetes_stateful_set_v1" "adot" {
  metadata {
    name      = "adot-collector"
    namespace = kubernetes_namespace_v1.insights.metadata[0].name
  }

  spec {
    service_name = kubernetes_service_v1.adot.metadata[0].name
    replicas     = 1

    selector {
      match_labels = local.adot_labels
    }

    template {
      metadata {
        labels = local.adot_labels
      }

      spec {
        service_account_name = kubernetes_service_account_v1.adot.metadata[0].name

        container {
          name  = "adot-collector"
          image = var.adot_image

          command = [
            "/awscollector",
            "--config=/conf/adot-collector.yaml",
          ]

          env {
            name  = "OTEL_RESOURCE_ATTRIBUTES"
            value = "ClusterName=${var.cluster_name}"
          }

          resources {
            requests = {
              cpu    = var.adot_cpu
              memory = var.adot_memory
            }
            limits = {
              cpu    = var.adot_cpu
              memory = var.adot_memory
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/conf"
          }
        }

        volume {
          name = "config"

          config_map {
            name = kubernetes_config_map_v1.adot.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    aws_eks_fargate_profile.insights,
    aws_cloudwatch_log_group.performance,
    kubernetes_cluster_role_binding_v1.adot,
  ]
}

# -------------------------------------------------------------------
# Amazon Managed Grafana (service-managed permissions: AWS creates and
# scopes the workspace role for the CloudWatch data source)
# -------------------------------------------------------------------
resource "aws_grafana_workspace" "this" {
  name                     = "${var.cluster_name}-grafana"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = var.grafana_authentication_providers
  permission_type          = "SERVICE_MANAGED"
  data_sources             = ["CLOUDWATCH"]
  tags                     = var.tags
}

resource "aws_grafana_role_association" "admin" {
  count = length(var.grafana_admin_user_ids) + length(var.grafana_admin_group_ids) > 0 ? 1 : 0

  workspace_id = aws_grafana_workspace.this.id
  role         = "ADMIN"
  user_ids     = length(var.grafana_admin_user_ids) > 0 ? var.grafana_admin_user_ids : null
  group_ids    = length(var.grafana_admin_group_ids) > 0 ? var.grafana_admin_group_ids : null
}

# Service account + short-lived token so Terraform can manage dashboards.
resource "aws_grafana_workspace_service_account" "terraform" {
  workspace_id = aws_grafana_workspace.this.id
  name         = "${var.cluster_name}-terraform"
  grafana_role = "ADMIN"
}

resource "aws_grafana_workspace_service_account_token" "terraform" {
  workspace_id       = aws_grafana_workspace.this.id
  service_account_id = aws_grafana_workspace_service_account.terraform.service_account_id
  name               = "${var.cluster_name}-terraform"
  seconds_to_live    = var.grafana_token_ttl_seconds
}
