###########################################
## S3 OUTPUTS
###########################################

output "lambda_artifacts_bucket_name" {
  description = "Name of the S3 bucket that stores Lambda deployment packages"
  value       = aws_s3_bucket.lambda_artifacts.id
}

output "lambda_artifacts_bucket_arn" {
  description = "ARN of the Lambda artifacts bucket (use in the GitHub OIDC role policy)"
  value       = aws_s3_bucket.lambda_artifacts.arn
}
