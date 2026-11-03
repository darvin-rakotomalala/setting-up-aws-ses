###########################################
## S3 VARIABLES
###########################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "kms_key_arn" {
  description = "The Amazon Resource Name (ARN) of the KMS key"
  type        = string
}
