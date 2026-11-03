###########################################
## API GATEWAY VARIABLES
###########################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "api_name" {
  type        = string
  description = "The name of the API."
}

variable "api_stage_name" {
  type        = string
  description = "The deployment stage name for the API (e.g., prod, staging, dev)."
}

variable "api_throttle_rate" {
  type        = number
  description = "Stage-wide steady-state requests/second."
}

variable "api_throttle_burst" {
  type        = number
  description = "The maximum burst limit (bucket capacity) for API Gateway throttling."
}

variable "api_method_throttle_rate" {
  type        = number
  description = "Tighter limit for the {proxy+} ANY method (protects Lambda concurrency and SES quota)."
}

variable "api_method_throttle_burst" {
  type        = number
  description = "The maximum burst limit (bucket capacity) for API Gateway method-level throttling."
}

variable "enable_api_cache" {
  type        = bool
  description = "Stage cache. Only helps GET endpoints; the POST contact endpoint is never cached."
}

variable "api_cache_size_gb" {
  type        = string
  description = "The capacity of the API Gateway stage cache in gigabytes."
}

variable "api_cache_ttl_seconds" {
  type        = number
  description = "The time-to-live (TTL) period, in seconds, that API responses are cached."
}

variable "lambda_alias_invoke_arn" {
  description = "ARN of the Lambda alias used by API Gateway"
  type        = string
}

variable "enable_xray" {
  type        = bool
  description = "Feature flag to determine whether to enable AWS X-Ray tracing for the Lambda function."
}

variable "log_group_api_arn" {
  type        = string
  description = "The ARN of the CloudWatch Log Group used by API Gateway."
}

variable "api_gateway_account_id" {
  type        = string
  description = "The ID of the API Gateway account settings."
}
