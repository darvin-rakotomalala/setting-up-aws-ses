###########################################
## LAMBDA VARIABLES
###########################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "lambda_exec_role_arn" {
  description = "Lambda execution role ARN."
  type        = string
}

variable "lambda_function_name" {
  type        = string
  description = "The name of the AWS Lambda function."
}

variable "lambda_alias_name" {
  type        = string
  description = "The name of the Lambda function alias (e.g., prod, live, or a version-specific identifier)."
}

variable "lambda_memory_mb" {
  type        = number
  description = "The amount of memory (in megabytes) allocated to the Lambda function."
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
  description = "The minimum number of provisioned concurrent executions for the Lambda function."
}

variable "provisioned_concurrency_max" {
  type        = number
  description = "The maximum number of provisioned concurrent executions for the Lambda function. Must be <= reserved_concurrency."
}

variable "provisioned_concurrency_target_utilization" {
  type        = number
  description = "The target utilization percentage for the provisioned concurrency autoscaling policy (e.g., 0.70 for 70%)."
}

variable "enable_xray" {
  type        = bool
  description = "Whether to enable AWS X-Ray tracing for the Lambda function."
}

variable "kms_key_arn" {
  description = "The Amazon Resource Name (ARN) of the KMS key"
  type        = string
}

variable "sender_email" {
  type        = string
  description = "Verified address mails are sent FROM (e.g. darvintojo@gmail.com)."

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.sender_email))
    error_message = "sender_email must be a valid email address."
  }
}

variable "local_recipient_email" {
  type        = string
  description = "The email address of the local recipient to receive notifications or alerts"
}

variable "local_use_snapstart" {
  type        = string
  description = "Flag or setting to determine whether to enable AWS Lambda SnapStart."
}

variable "local_use_provisioned" {
  type        = string
  description = "Flag or setting to determine whether to use provisioned concurrency."
}

variable "ses_configuration_set" {
  description = "The name of the SES v2 configuration set."
  type        = string
}

variable "log_group_lambda_name" {
  description = "The name of the CloudWatch Log Group for the Lambda function."
  type        = string
}

variable "api_lambda_api_execution_arn" {
  description = "REST API Gateway for Lambda execution ARN"
  type        = string
}

variable "iam_role_policy_lambda_kms" {
  type        = string
  description = "The ID of the IAM role policy allowing the Lambda function to use the KMS key[cite: 1]."
}

variable "iam_role_policy_lambda_logs" {
  type        = string
  description = "The ID of the IAM role policy allowing the Lambda function to write logs to its CloudWatch Log Group[cite: 1]."
}

variable "iam_role_policy_attachment_ses_send" {
  type        = string
  description = "The ID of the IAM role policy attachment granting the Lambda function permission to send emails via SES[cite: 1]."
}
