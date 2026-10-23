output "role_arn" {
  description = "Annotate the service account with eks.amazonaws.com/role-arn = this value."
  value       = aws_iam_role.this.arn
}
