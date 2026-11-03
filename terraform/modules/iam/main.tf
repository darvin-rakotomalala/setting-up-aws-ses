#######################################################
# IAM role for Terraform execution (used in CI/CD)
#######################################################

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "terraform_execution" {
  name = "${var.naming_prefix}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.current_account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}*/${var.github_repo}*:*"
          }
        }
      }
    ]
  })

  # Maximum session duration (1 hour for Terraform runs)
  max_session_duration = 3600

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-github-actions-oidc"
  })
}

resource "aws_iam_role_policy_attachment" "terraform_execution_admin" {
  role = aws_iam_role.terraform_execution.name
  # Bad: Overly permissions
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" # Scope down in production. Specific permissions for specific resources
}

###############################################################################
# Lambda execution role (least privilege)
###############################################################################

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.current_account_id]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.naming_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# --- SES: send only from the verified sender, only through our config set ----
data "aws_iam_policy_document" "ses_send" {
  statement {
    sid     = "SendFromVerifiedSender"
    actions = ["ses:SendEmail"]
    resources = concat(
      [var.sender_identity_arn, var.ses_configuration_set_arn],
      var.recipient_email_identity_arns,
    )
    condition {
      test     = "StringEquals"
      variable = "ses:FromAddress"
      values   = [var.sender_email]
    }
  }
}

resource "aws_iam_policy" "ses_send" {
  name   = "${var.naming_prefix}-ses-send-email"
  policy = data.aws_iam_policy_document.ses_send.json
}

resource "aws_iam_role_policy_attachment" "ses_send" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.ses_send.arn
}

# --- KMS: decrypt env vars / SnapStart snapshots ----------------------------
data "aws_iam_policy_document" "lambda_kms" {
  statement {
    sid       = "UseProjectKey"
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
    resources = [var.kms_key_arn]
  }
}

resource "aws_iam_role_policy" "lambda_kms" {
  name   = "${var.naming_prefix}-kms-use"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_kms.json
}

# --- Logs: scoped to OUR log group instead of AWSLambdaBasicExecutionRole's "*" ---
data "aws_iam_policy_document" "lambda_logs" {
  statement {
    sid       = "WriteOwnLogGroup"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${var.log_group_lambda_arn}:*"]
  }
}

resource "aws_iam_role_policy" "lambda_logs" {
  name   = "logs-write"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_logs.json
}

# --- X-Ray (these actions do not support resource-level permissions) ---------
data "aws_iam_policy_document" "lambda_xray" {
  count = var.enable_xray ? 1 : 0
  statement {
    actions   = ["xray:PutTraceSegments", "xray:PutTelemetryRecords"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda_xray" {
  count  = var.enable_xray ? 1 : 0
  name   = "xray-write"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_xray[0].json
}

###############################################################################
# API Gateway -> CloudWatch account role (singleton per account/region)
###############################################################################
data "aws_iam_policy_document" "apigw_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "apigw_logs" {
  count              = var.manage_api_gateway_account ? 1 : 0
  name               = "${var.naming_prefix}-apigw-cloudwatch"
  assume_role_policy = data.aws_iam_policy_document.apigw_assume.json
}

resource "aws_iam_role_policy_attachment" "apigw_logs" {
  count      = var.manage_api_gateway_account ? 1 : 0
  role       = aws_iam_role.apigw_logs[0].name
  policy_arn = "arn:${var.current_partition}:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "this" {
  count               = var.manage_api_gateway_account ? 1 : 0
  cloudwatch_role_arn = aws_iam_role.apigw_logs[0].arn
  depends_on          = [aws_iam_role_policy_attachment.apigw_logs]
}
