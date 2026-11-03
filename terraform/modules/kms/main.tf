#######################################################
# KMS
#######################################################

###############################################################################
# One customer-managed key for: CloudWatch log groups, SNS topics, the S3
# artifacts bucket and Lambda environment variables.
#
# NOTE: SES does not let you encrypt sending identities with a customer key.
# Its data at rest is encrypted with AWS-owned keys. KMS protects what
# surrounds SES here (logs, bounce/complaint events, config, artifacts).
###############################################################################

data "aws_iam_policy_document" "kms" {
  statement {
    sid       = "EnableIAMPolicies"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${var.current_partition}:iam::${var.current_account_id}:root"]
    }
  }

  statement {
    sid = "AllowCloudWatchLogs"
    actions = [
      "kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*",
      "kms:GenerateDataKey*", "kms:Describe*",
    ]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["logs.${var.primary_region}.amazonaws.com"]
    }
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:${var.current_partition}:logs:${var.primary_region}:${var.current_account_id}:log-group:*"]
    }
  }

  statement {
    sid       = "AllowAlarmsAndSesToPublishToEncryptedSns"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey*"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com", "ses.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.current_account_id]
    }
  }
}

resource "aws_kms_key" "main" {
  description             = "${var.naming_prefix} - logs, SNS, artifacts, Lambda env"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.kms.json
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.naming_prefix}-ses-backend"
  target_key_id = aws_kms_key.main.key_id
}
