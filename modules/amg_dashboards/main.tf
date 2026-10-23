locals {
  datasource_name = coalesce(var.cloudwatch_datasource_name, "CloudWatch ${var.region}")

  base_dimensions = {
    ClusterName = var.cluster_name
    LaunchType  = "fargate"
  }

  # One entry per panel. The dimension sets match what the ADOT awsemf exporter publishes:
  # [ClusterName, LaunchType], [ClusterName, Namespace, LaunchType], [ClusterName, Namespace, PodName, LaunchType]
  panel_defs = [
    {
      title      = "Pod CPU utilization over limit, by namespace (%)"
      metric     = "pod_cpu_utilization_over_pod_limit"
      statistic  = "Average"
      unit       = "percent"
      dimensions = merge(local.base_dimensions, { Namespace = "*" })
      label      = "$${PROP('Dim.Namespace')}"
    },
    {
      title      = "Pod memory utilization over limit, by namespace (%)"
      metric     = "pod_memory_utilization_over_pod_limit"
      statistic  = "Average"
      unit       = "percent"
      dimensions = merge(local.base_dimensions, { Namespace = "*" })
      label      = "$${PROP('Dim.Namespace')}"
    },
    {
      title      = "Network received, by namespace"
      metric     = "pod_network_rx_bytes"
      statistic  = "Sum"
      unit       = "Bps"
      dimensions = merge(local.base_dimensions, { Namespace = "*" })
      label      = "$${PROP('Dim.Namespace')}"
    },
    {
      title      = "Network transmitted, by namespace"
      metric     = "pod_network_tx_bytes"
      statistic  = "Sum"
      unit       = "Bps"
      dimensions = merge(local.base_dimensions, { Namespace = "*" })
      label      = "$${PROP('Dim.Namespace')}"
    },
    {
      title      = "Pod CPU utilization over limit, by pod (%)"
      metric     = "pod_cpu_utilization_over_pod_limit"
      statistic  = "Average"
      unit       = "percent"
      dimensions = merge(local.base_dimensions, { Namespace = "*", PodName = "*" })
      label      = "$${PROP('Dim.Namespace')}/$${PROP('Dim.PodName')}"
    },
    {
      title      = "Pod memory utilization over limit, by pod (%)"
      metric     = "pod_memory_utilization_over_pod_limit"
      statistic  = "Average"
      unit       = "percent"
      dimensions = merge(local.base_dimensions, { Namespace = "*", PodName = "*" })
      label      = "$${PROP('Dim.Namespace')}/$${PROP('Dim.PodName')}"
    },
  ]
}

resource "grafana_data_source" "cloudwatch" {
  name       = local.datasource_name
  type       = "cloudwatch"
  is_default = true

  json_data_encoded = jsonencode({
    authType      = "default"
    defaultRegion = var.region
  })
}

locals {
  datasource_ref = {
    type = "cloudwatch"
    uid  = grafana_data_source.cloudwatch.uid
  }

  panels = [
    for i, p in local.panel_defs : {
      id         = i + 1
      type       = "timeseries"
      title      = p.title
      datasource = local.datasource_ref
      gridPos = {
        h = 8
        w = 12
        x = (i % 2) * 12
        y = floor(i / 2) * 8
      }
      fieldConfig = {
        defaults  = { unit = p.unit }
        overrides = []
      }
      options = {
        legend  = { displayMode = "list", placement = "bottom" }
        tooltip = { mode = "multi" }
      }
      targets = [
        {
          refId            = "A"
          datasource       = local.datasource_ref
          queryMode        = "Metrics"
          metricQueryType  = 0
          metricEditorMode = 0
          namespace        = "ContainerInsights"
          metricName       = p.metric
          dimensions       = p.dimensions
          matchExact       = true
          statistic        = p.statistic
          region           = "default"
          period           = ""
          id               = ""
          expression       = ""
          label            = p.label
        }
      ]
    }
  ]

  dashboard = {
    uid           = "eks-fargate-overview"
    title         = "EKS Fargate overview (${var.cluster_name})"
    tags          = ["eks", "fargate", "container-insights"]
    timezone      = "browser"
    schemaVersion = 39
    version       = 1
    refresh       = "1m"
    time          = { from = "now-3h", to = "now" }
    panels        = local.panels
  }
}

resource "grafana_dashboard" "eks_fargate_overview" {
  config_json = jsonencode(local.dashboard)
  overwrite   = true
}
