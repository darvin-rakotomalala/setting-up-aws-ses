###########################################
## IAM VARIABLES
###########################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "current_account_id" {
  description = "Current account ID"
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

variable "current_partition" {
  description = "Current partition account ID"
  type        = string
  # default = data.aws_partition.current.partition
}

variable "manage_api_gateway_account" {
  type        = bool
  description = "API Gateway's CloudWatch role is an account+region singleton. Set false if it is already configured."
}

variable "sender_identity_arn" {
  type        = string
  description = "The ARN of the verified SES v2 email identity."
}

variable "ses_configuration_set_arn" {
  description = "The Amazon Resource Name (ARN) of the SES v2 configuration set."
  type        = string
}

variable "recipient_email_identity_arns" {
  description = "The Amazon Resource Name (ARN) of the recipient email identity."
  type        = list(string)
}

variable "sender_email" {
  type        = string
  description = "Verified address mails are sent FROM (e.g. darvintojo@gmail.com)."

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.sender_email))
    error_message = "sender_email must be a valid email address."
  }
}

variable "kms_key_arn" {
  description = "The Amazon Resource Name (ARN) of the KMS key"
  type        = string
}

variable "log_group_lambda_arn" {
  type        = string
  description = "The Amazon Resource Name (ARN) of the Lambda CloudWatch log group."
}

variable "enable_xray" {
  type        = bool
  description = "Whether to enable AWS X-Ray tracing for the service."
}
