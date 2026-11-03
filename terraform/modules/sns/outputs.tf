###########################################
## SNS OUTPUTS
###########################################

output "alert_topic_arns" {
  description = "A map of alert names to their corresponding SNS topic ARNs"
  value       = { for k, t in aws_sns_topic.alerts : k => t.arn }
}

output "sns_topic_policy_arns" {
  description = "A map of alert names to their corresponding SNS topic policy ARNs"
  value       = { for k, p in aws_sns_topic_policy.alerts : k => p.id }
}
