###########################################
## SNS VARIABLES
###########################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "alarm_emails" {
  type        = list(string)
  description = "Receive both critical and warning alerts. Add PagerDuty/OpsGenie/Slack as extra aws_sns_topic_subscription on the critical/warning topics."
}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "current_partition" {
  description = "Current partition account ID"
  type        = string
}

variable "kms_key_arn" {
  description = "The Amazon Resource Name (ARN) of the KMS key"
  type        = string
}
