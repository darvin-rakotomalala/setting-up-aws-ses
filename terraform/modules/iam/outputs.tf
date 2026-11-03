###########################################
## IAM OUTPUTS
###########################################

output "iam_role_terraform_execution_arn" {
  description = "IAM role terraform execution ARN"
  value       = aws_iam_role.terraform_execution.arn
}

output "lambda_exec_role_arn" {
  description = "Lambda execution role ARN."
  value       = aws_iam_role.lambda.arn
}

output "send_policy_arn" {
  description = "Attach to any other IAM role that must send mail through this identity."
  value       = aws_iam_policy.ses_send.arn
}

output "iam_role_policy_lambda_kms" {
  value       = aws_iam_role_policy.lambda_kms.id
  description = "The ID of the IAM role policy allowing the Lambda function to use the KMS key."
}

output "iam_role_policy_lambda_logs" {
  value       = aws_iam_role_policy.lambda_logs.id
  description = "The ID of the IAM role policy allowing the Lambda function to write logs to its CloudWatch Log Group."
}

output "iam_role_policy_attachment_ses_send" {
  value       = aws_iam_role_policy_attachment.ses_send.id
  description = "The ID of the IAM role policy attachment granting the Lambda function permission to send emails via SES."
}

output "api_gateway_account_configured" {
  value       = length(aws_api_gateway_account.this) > 0
  description = "Indicates whether the API Gateway account settings are managed."
}
