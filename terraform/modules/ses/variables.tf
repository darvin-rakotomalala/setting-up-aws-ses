###########################################
## SES VARIABLES
###########################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "sender_email" {
  type        = string
  description = "Verified address mails are sent FROM (e.g. darvintojo@gmail.com)."

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.sender_email))
    error_message = "sender_email must be a valid email address."
  }
}

variable "alert_topic_arns" {
  description = "A map of alert names to their corresponding SNS topic ARNs"
  type        = map(string)
}

variable "sns_topic_policy_arns" {
  description = "A map of alert names to their corresponding SNS topic policy ARNs"
  type        = map(string)
}

variable "local_separate_recipient" {
  type        = string
  description = "Flag or identifier to determine whether a separate recipient should be used for notifications"
}

variable "local_recipient_email" {
  type        = string
  description = "The email address of the local recipient to receive notifications or alerts"
}
