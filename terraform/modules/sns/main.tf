#######################################################
# SNS
#######################################################

# Alert topics (encrypted). critical -> page someone (PagerDuty / OpsGenie)
#                           warning  -> Slack / email

resource "aws_sns_topic" "alerts" {
  for_each          = toset(["critical", "warning"])
  name              = "${var.naming_prefix}-alerts-${each.key}"
  kms_master_key_id = var.kms_key_arn
}

data "aws_iam_policy_document" "alerts" {
  for_each = aws_sns_topic.alerts

  statement {
    sid       = "OwnerAccount"
    actions   = ["sns:Publish", "sns:Subscribe", "sns:GetTopicAttributes", "sns:SetTopicAttributes", "sns:ListSubscriptionsByTopic", "sns:DeleteTopic", "sns:AddPermission", "sns:RemovePermission"]
    resources = [each.value.arn]
    principals {
      type        = "AWS"
      identifiers = ["arn:${var.current_partition}:iam::${var.current_account_id}:root"]
    }
  }

  statement {
    sid       = "AllowAlarmsAndSesPublish"
    actions   = ["sns:Publish"]
    resources = [each.value.arn]
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

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["sns:Publish"]
    resources = [each.value.arn]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_sns_topic_policy" "alerts" {
  for_each = aws_sns_topic.alerts
  arn      = each.value.arn
  policy   = data.aws_iam_policy_document.alerts[each.key].json
}

resource "aws_sns_topic_subscription" "email" {
  for_each = {
    for pair in setproduct(keys(aws_sns_topic.alerts), var.alarm_emails) :
    "${pair[0]}-${pair[1]}" => { topic = pair[0], email = pair[1] }
  }
  topic_arn = aws_sns_topic.alerts[each.value.topic].arn
  protocol  = "email"
  endpoint  = each.value.email
}
