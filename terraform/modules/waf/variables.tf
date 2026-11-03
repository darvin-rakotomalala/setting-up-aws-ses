###########################################
## WAF VARIABLES
###########################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "enable_waf" {
  type        = bool
  description = "Attach a WAFv2 ACL (per-IP rate limit + AWS common rules). Adds monthly cost."
}

variable "waf_rate_limit" {
  type        = number
  description = "Max requests per IP per 5 minutes."
}

variable "rest_api_stage_arn" {
  description = "ARN of the API Gateway REST API."
  type        = string
}
