############################################
# MAIN OUTPUTS
############################################

output "iam_role_terraform_execution_arn" {
  description = "IAM role terraform execution ARN"
  value       = module.iam.iam_role_terraform_execution_arn
}

output "lambda_function_name" {
  description = "Name of the deployed Lambda function"
  value       = module.lambda.lambda_function_name
}

output "lambda_function_arn" {
  description = "ARN of the deployed Lambda function"
  value       = module.lambda.lambda_function_arn
}

output "lambda_function_version" {
  description = "Published version of the Lambda function (SnapStart applies to this version)"
  value       = module.lambda.lambda_function_version
}

output "lambda_alias_name" {
  description = "Name of the Lambda alias used by API Gateway"
  value       = module.lambda.lambda_alias_name
}

output "lambda_cloudwatch_log_group" {
  description = "CloudWatch Log group for the Lambda function"
  value       = module.cloudwatch.log_groups_name.lambda
}

output "api_invoke_url" {
  description = "Base invoke URL for the deployed API Gateway dev stage"
  value       = module.apigateway.api_invoke_url
}

output "lambda_artifacts_bucket_name" {
  description = "Set this as the ARTIFACT_BUCKET variable in the GitHub dev environment"
  value       = module.s3.lambda_artifacts_bucket_name
}
