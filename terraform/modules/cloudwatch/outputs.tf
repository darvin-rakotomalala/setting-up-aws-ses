###########################################
## CLOUDWATCH OUTPUTS
###########################################

output "log_groups_name" {
  value = {
    lambda = aws_cloudwatch_log_group.lambda.name
    app    = aws_cloudwatch_log_group.app.name
    api    = aws_cloudwatch_log_group.api.name
  }
  description = "A map of names for the Lambda, application, and API CloudWatch Log Groups."
}

output "log_groups_arn" {
  value = {
    lambda = aws_cloudwatch_log_group.lambda.arn
    app    = aws_cloudwatch_log_group.app.arn
    api    = aws_cloudwatch_log_group.api.arn
  }
  description = "A map of ARNs for the Lambda, application, and API CloudWatch Log Groups."
}
