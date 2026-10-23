# Fargate log routing (Fluent Bit) runs with the pod execution role, so that role
# needs CloudWatch Logs permissions. Scoped to this cluster's /aws/eks/<name>/ log groups.
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  log_group_prefix = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/${var.cluster_name}"
}

data "aws_iam_policy_document" "fargate_logging" {
  statement {
    sid = "FargateLogRouting"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
    resources = [
      "${local.log_group_prefix}/*",
      "${local.log_group_prefix}/*:*",
    ]
  }
}

resource "aws_iam_role_policy" "fargate_logging" {
  name   = "${var.cluster_name}-fargate-logging"
  role   = aws_iam_role.fargate.id
  policy = data.aws_iam_policy_document.fargate_logging.json
}
