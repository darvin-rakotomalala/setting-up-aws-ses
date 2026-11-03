#######################################################
# SES
#######################################################

###############################################################################
# Amazon SES - email address verification only (no domain, no DNS)
# After `terraform apply`, click the link AWS emails to each address.
# Terraform cannot complete that step.
###############################################################################

resource "aws_sesv2_configuration_set" "main" {
  configuration_set_name = "${var.naming_prefix}-ses"

  delivery_options {
    tls_policy = "REQUIRE"
  }

  reputation_options {
    reputation_metrics_enabled = true
  }

  sending_options {
    sending_enabled = true
  }

  suppression_options {
    suppressed_reasons = ["BOUNCE", "COMPLAINT"]
  }
}

# Bounce / complaint / reject events -> encrypted SNS (warning topic)
resource "aws_sesv2_configuration_set_event_destination" "alerts" {
  configuration_set_name = aws_sesv2_configuration_set.main.configuration_set_name
  event_destination_name = "bounce-complaint-to-sns"

  event_destination {
    enabled              = true
    matching_event_types = ["BOUNCE", "COMPLAINT", "REJECT"]

    sns_destination {
      topic_arn = var.alert_topic_arns["warning"]
    }
  }

  depends_on = [var.sns_topic_policy_arns]
}

resource "aws_sesv2_email_identity" "sender" {
  email_identity         = var.sender_email
  configuration_set_name = aws_sesv2_configuration_set.main.configuration_set_name
}

# Needed only while the account is in the SES sandbox and the owner mailbox
# differs from the sender.
resource "aws_sesv2_email_identity" "recipient" {
  count                  = var.local_separate_recipient ? 1 : 0
  email_identity         = var.local_recipient_email
  configuration_set_name = aws_sesv2_configuration_set.main.configuration_set_name
}
