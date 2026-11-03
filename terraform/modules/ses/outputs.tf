###########################################
## SES OUTPUTS
###########################################

output "sender_identity_arn" {
  value       = aws_sesv2_email_identity.sender.arn
  description = "The ARN of the verified SES v2 email identity."
}

output "ses_configuration_set" {
  value       = aws_sesv2_configuration_set.main.configuration_set_name
  description = "The name of the SES v2 configuration set."
}

output "ses_configuration_set_arn" {
  description = "The Amazon Resource Name (ARN) of the SES v2 configuration set."
  value       = aws_sesv2_configuration_set.main.arn
}

output "recipient_email_identity_arns" {
  description = "The Amazon Resource Name (ARN) of the recipient email identity."
  value       = aws_sesv2_email_identity.recipient[*].arn
}
