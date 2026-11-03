############################################
# MAIN VARIABLES
############################################

variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "team_name" {
  description = "Team name"
  type        = string
}

variable "cost_center" {
  description = "Cost center"
  type        = string
}

variable "compliance" {
  description = "Compliance"
  type        = string
}

variable "bucket_name" {
  description = "Bucket name"
  type        = string
}

variable "github_org" {
  description = "GitHub organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository"
  type        = string
}

variable "enable_waf" {
  type        = bool
  description = "Attach a WAFv2 ACL (per-IP rate limit + AWS common rules). Adds monthly cost."
}

variable "waf_rate_limit" {
  type        = number
  description = "Max requests per IP per 5 minutes."
}

variable "alarm_emails" {
  type        = list(string)
  description = "Receive both critical and warning alerts. Add PagerDuty/OpsGenie/Slack as extra aws_sns_topic_subscription on the critical/warning topics."
}

variable "sender_email" {
  type        = string
  description = "Verified address mails are sent FROM (e.g. darvintojo@gmail.com)."

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.sender_email))
    error_message = "sender_email must be a valid email address."
  }
}

variable "lambda_function_name" {
  type = string
}

variable "lambda_alias_name" {
  type = string
}

variable "lambda_memory_mb" {
  type        = number
  description = "The amount of memory in megabytes allocated to the Lambda function."
}

variable "lambda_timeout_seconds" {
  type        = number
  description = "API Gateway caps the effective limit at 29 s."
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

variable "cold_start_strategy" {
  type        = string
  description = "\"snapstart\" or \"provisioned\". They are mutually exclusive on one function version."

  validation {
    condition     = contains(["snapstart", "provisioned"], var.cold_start_strategy)
    error_message = "cold_start_strategy must be \"snapstart\" or \"provisioned\"."
  }
}

variable "provisioned_concurrency_min" {
  type        = number
  description = "The minimum number of provisioned concurrency instances to maintain for the Lambda function."
}

variable "provisioned_concurrency_max" {
  type        = number
  description = "Must be <= reserved_concurrency."
}

variable "provisioned_concurrency_target_utilization" {
  type        = number
  description = "The target utilization percentage for Lambda provisioned concurrency, expressed as a decimal (e.g., 0.7 for 70%)."
}

variable "enable_xray" {
  type        = bool
  description = "A flag to enable or disable AWS X-Ray tracing for the Lambda function."
}

variable "manage_api_gateway_account" {
  type        = bool
  description = "API Gateway's CloudWatch role is an account+region singleton. Set false if it is already configured."
}

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

variable "recipient_email" {
  type        = string
  description = "Site owner address that receives contact messages. Defaults to sender_email. While SES is in sandbox it must also be verified (done automatically here)."
}
