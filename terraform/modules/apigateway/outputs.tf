###########################################
## API GATEWAY OUTPUTS
###########################################


output "contact_endpoint" {
  description = "POST JSON {senderName, senderEmail, senderSubject, senderMessage} here."
  value       = "${aws_api_gateway_stage.this.invoke_url}/api/contact"
}

output "rest_api_stage_arn" {
  description = "ARN of the API Gateway REST API."
  value       = aws_api_gateway_stage.this.arn
}

output "rest_api_id" {
  description = "REST API ID."
  value       = aws_api_gateway_rest_api.this.id
}

output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.this.id
}

output "api_invoke_url" {
  description = "Base invoke URL for the deployed API Gateway dev stage"
  value       = aws_api_gateway_stage.this.invoke_url
}

output "api_lambda_api_execution_arn" {
  description = "REST API Gateway for Lambda execution ARN"
  value       = aws_api_gateway_rest_api.this.execution_arn
}

output "java_lambda_api_name" {
  description = "Name of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.this.name
}

output "java_lambda_api_stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.this.stage_name
}
