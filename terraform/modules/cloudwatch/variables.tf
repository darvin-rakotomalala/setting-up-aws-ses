###########################################
## CLOUDWATCH VARIABLES
###########################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "log_retention_days" {
  type        = number
  description = "The number of days to retain logs in the CloudWatch log group."
}

variable "lambda_duration_threshold_ms" {
  type        = number
  description = "The duration threshold in milliseconds used to trigger Lambda execution time alarms."
}

variable "api_5xx_threshold" {
  type        = number
  description = "The threshold count for API Gateway 5xx server errors before triggering an alarm."
}

variable "api_4xx_threshold" {
  type        = number
  description = "The threshold count for API Gateway 4xx client errors before triggering an alarm."
}

variable "api_latency_threshold_ms" {
  type        = number
  description = "The latency threshold in milliseconds for API requests before triggering an alarm."
}

variable "api_integration_latency_threshold_ms" {
  type        = number
  description = "The integration latency threshold in milliseconds for API Gateway backend integrations before triggering an alarm."
}

variable "local_log_group_lambda" {
  type        = string
  description = "The name or path of the local log group dedicated to Lambda function logs."
}

variable "kms_key_arn" {
  type        = string
  description = "The Amazon Resource Name (ARN) of the KMS key"
}

variable "local_log_group_app" {
  type        = string
  description = "The name or path of the local log group dedicated to application logs."
}

variable "local_log_group_api" {
  type        = string
  description = "The name or path of the local log group dedicated to API Gateway logs."
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the deployed Lambda function"
  type        = string
}

variable "java_lambda_api_name" {
  description = "Name of the API Gateway REST API"
  type        = string
}


variable "java_lambda_api_stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
}

/*
variable "reserved_concurrency" {
  type        = number
  description = "Reserved concurrency. The account must keep >= 10 unreserved executions, so brand-new accounts (limit 10) must request a quota increase first."

  validation {
    condition     = var.reserved_concurrency >= 1
    error_message = "reserved_concurrency must be >= 1."
  }
}
*/

variable "alert_topic_arns" {
  description = "A map of alert names to their corresponding SNS topic ARNs"
  type        = map(string)
}
