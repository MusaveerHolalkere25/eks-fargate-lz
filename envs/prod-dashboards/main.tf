provider "grafana" {
  url  = "https://${var.grafana_endpoint}"
  auth = var.grafana_auth
}

module "amg_dashboards" {
  source = "../../modules/amg_dashboards"

  region       = var.region
  cluster_name = "${var.project}-${var.environment}"
}
