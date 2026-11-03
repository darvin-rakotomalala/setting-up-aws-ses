locals {
  common_tags = {
    ManagedBy   = "Terraform"
    Region      = var.primary_region # primary or secondary
    Environment = var.environment    # dev, staging, prod
    Project     = var.project_name   # ce
    Owner       = var.team_name      # demo
    CostCenter  = var.cost_center    # "engineering"
    Compliance  = var.compliance     # "internal"
    # The timestamp() function returns a UTC timestamp string in RFC 3339 format.
    deployment_timestamp = timestamp()
  }

  naming_prefix = "${var.project_name}-${var.environment}"

  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  recipient_email    = coalesce(var.recipient_email, var.sender_email)
  separate_recipient = local.recipient_email != var.sender_email

  # Log group names come from the technical spec.
  log_group_lambda = "SpringBoot_SESEmailBackend_Logs"
  log_group_app    = "SpringBoot_ContactFormApi_Logs"
  log_group_api    = "SpringBoot_SESEmailBackendApi_Logs"

  use_snapstart   = var.cold_start_strategy == "snapstart"
  use_provisioned = var.cold_start_strategy == "provisioned"
}
