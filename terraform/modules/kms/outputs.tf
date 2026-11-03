###########################################
## KMS OUTPUTS
###########################################

output "kms_key_arn" {
  description = "The Amazon Resource Name (ARN) of the KMS key"
  value       = aws_kms_key.main.arn
}

output "kms_key_alias" {
  description = "The display name/alias of the KMS key"
  value       = aws_kms_alias.main.name
}