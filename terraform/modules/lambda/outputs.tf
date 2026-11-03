###########################################
## LAMBDA OUTPUTS
###########################################


output "lambda_function_name" {
  description = "Name of the deployed Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
  description = "ARN of the deployed Lambda function"
  value       = aws_lambda_function.this.arn
}

output "lambda_alias_invoke_arn" {
  description = "ARN of the Lambda alias used by API Gateway"
  value       = aws_lambda_alias.live.invoke_arn
}

output "lambda_alias_name" {
  description = "Name of the Lambda alias used by API Gateway"
  value       = aws_lambda_alias.live.name
}

output "lambda_function_version" {
  description = "Published version of the Lambda function (SnapStart applies to this version)"
  value       = aws_lambda_function.this.version
}

output "lambda_published_version" {
  description = "Latest published (SnapStart) version."
  value       = aws_lambda_function.this.version
}
