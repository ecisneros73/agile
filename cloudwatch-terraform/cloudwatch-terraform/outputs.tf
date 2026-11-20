output "cloudwatch_log_group_names" {
  description = "Names of the managed CloudWatch Logs groups."
  value       = keys(aws_cloudwatch_log_group.groups)
}

output "cloudwatch_log_group_arns" {
  description = "ARNs of the managed CloudWatch Logs groups."
  value       = { for name, group in aws_cloudwatch_log_group.groups : name => group.arn }
}
