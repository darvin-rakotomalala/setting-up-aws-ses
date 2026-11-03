#########################################################
# IAM
#########################################################

module "iam" {
  source                        = "./modules/iam"
  naming_prefix                 = local.naming_prefix
  common_tags                   = local.common_tags
  current_account_id            = local.account_id
  current_partition             = local.partition
  github_org                    = var.github_org
  github_repo                   = var.github_repo
  kms_key_arn                   = module.kms.kms_key_arn
  log_group_lambda_arn          = module.cloudwatch.log_groups_arn.lambda
  recipient_email_identity_arns = module.ses.recipient_email_identity_arns
  sender_email                  = var.sender_email
  sender_identity_arn           = module.ses.sender_identity_arn
  ses_configuration_set_arn     = module.ses.ses_configuration_set_arn
  enable_xray                   = var.enable_xray
  manage_api_gateway_account    = var.manage_api_gateway_account
}

#########################################################
# LAMBDA
#########################################################

module "lambda" {
  source                                     = "./modules/lambda"
  naming_prefix                              = local.naming_prefix
  common_tags                                = local.common_tags
  api_lambda_api_execution_arn               = module.apigateway.api_lambda_api_execution_arn
  iam_role_policy_attachment_ses_send        = module.iam.iam_role_policy_attachment_ses_send
  iam_role_policy_lambda_kms                 = module.iam.iam_role_policy_lambda_kms
  iam_role_policy_lambda_logs                = module.iam.iam_role_policy_lambda_logs
  kms_key_arn                                = module.kms.kms_key_arn
  lambda_exec_role_arn                       = module.iam.lambda_exec_role_arn
  local_recipient_email                      = local.recipient_email
  local_use_provisioned                      = local.use_provisioned
  local_use_snapstart                        = local.use_snapstart
  log_group_lambda_name                      = module.cloudwatch.log_groups_name.lambda
  sender_email                               = var.sender_email
  ses_configuration_set                      = module.ses.ses_configuration_set
  cold_start_strategy                        = var.cold_start_strategy
  enable_xray                                = var.enable_xray
  lambda_alias_name                          = var.lambda_alias_name
  lambda_function_name                       = var.lambda_function_name
  lambda_memory_mb                           = var.lambda_memory_mb
  lambda_timeout_seconds                     = var.lambda_timeout_seconds
  provisioned_concurrency_max                = var.provisioned_concurrency_max
  provisioned_concurrency_min                = var.provisioned_concurrency_min
  provisioned_concurrency_target_utilization = var.provisioned_concurrency_target_utilization
  # reserved_concurrency                       = var.reserved_concurrency
}

#########################################################
# API GATEWAY
#########################################################

module "apigateway" {
  source                    = "./modules/apigateway"
  naming_prefix             = local.naming_prefix
  common_tags               = local.common_tags
  api_gateway_account_id    = module.iam.api_gateway_account_configured
  lambda_alias_invoke_arn   = module.lambda.lambda_alias_invoke_arn
  log_group_api_arn         = module.cloudwatch.log_groups_arn.api
  api_cache_size_gb         = var.api_cache_size_gb
  api_cache_ttl_seconds     = var.api_cache_ttl_seconds
  api_method_throttle_burst = var.api_method_throttle_burst
  api_method_throttle_rate  = var.api_method_throttle_rate
  api_name                  = var.api_name
  api_stage_name            = var.api_stage_name
  api_throttle_burst        = var.api_throttle_burst
  api_throttle_rate         = var.api_throttle_rate
  enable_api_cache          = var.enable_api_cache
  enable_xray               = var.enable_xray
}

#########################################################
## KMS
#########################################################

module "kms" {
  source             = "./modules/kms"
  naming_prefix      = local.naming_prefix
  common_tags        = local.common_tags
  current_account_id = local.account_id
  current_partition  = local.partition
  primary_region     = var.primary_region
}

#########################################################
## CLOUDWATCH
#########################################################

module "cloudwatch" {
  source                               = "./modules/cloudwatch"
  naming_prefix                        = local.naming_prefix
  common_tags                          = local.common_tags
  alert_topic_arns                     = module.sns.alert_topic_arns
  environment                          = var.environment
  java_lambda_api_name                 = module.apigateway.java_lambda_api_name
  java_lambda_api_stage_name           = module.apigateway.java_lambda_api_stage_name
  kms_key_arn                          = module.kms.kms_key_arn
  lambda_function_name                 = var.lambda_function_name
  local_log_group_api                  = local.log_group_api
  local_log_group_app                  = local.log_group_app
  local_log_group_lambda               = local.log_group_lambda
  project_name                         = var.project_name
  api_4xx_threshold                    = var.api_4xx_threshold
  api_5xx_threshold                    = var.api_5xx_threshold
  api_integration_latency_threshold_ms = var.api_integration_latency_threshold_ms
  api_latency_threshold_ms             = var.api_latency_threshold_ms
  lambda_duration_threshold_ms         = var.lambda_duration_threshold_ms
  log_retention_days                   = var.log_retention_days
  # reserved_concurrency                 = var.reserved_concurrency
}

#########################################################
## SNS
#########################################################

module "sns" {
  source             = "./modules/sns"
  naming_prefix      = local.naming_prefix
  common_tags        = local.common_tags
  current_account_id = local.account_id
  current_partition  = local.partition
  kms_key_arn        = module.kms.kms_key_arn
  alarm_emails       = var.alarm_emails
}

#########################################################
# SES
#########################################################

module "ses" {
  source                   = "./modules/ses"
  naming_prefix            = local.naming_prefix
  common_tags              = local.common_tags
  alert_topic_arns         = module.sns.alert_topic_arns
  sns_topic_policy_arns    = module.sns.sns_topic_policy_arns
  local_recipient_email    = local.recipient_email
  local_separate_recipient = local.separate_recipient
  sender_email             = var.sender_email
}

#########################################################
# WAF
#########################################################

module "waf" {
  source             = "./modules/waf"
  naming_prefix      = local.naming_prefix
  common_tags        = local.common_tags
  rest_api_stage_arn = module.apigateway.rest_api_stage_arn
  enable_waf         = var.enable_waf
  waf_rate_limit     = var.waf_rate_limit
}

#########################################################
# S3
#########################################################

module "s3" {
  source        = "./modules/s3"
  naming_prefix = local.naming_prefix
  common_tags   = local.common_tags
  kms_key_arn   = module.kms.kms_key_arn
}
