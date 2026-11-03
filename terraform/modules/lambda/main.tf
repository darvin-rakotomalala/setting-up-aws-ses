################################################=======
# LAMBDA
#######################################################

# Lambda: Spring Boot 4 on Java 21
resource "aws_lambda_function" "this" {
  function_name = var.lambda_function_name
  description   = "AWS Serverless Spring Boot 4 API"
  role          = var.lambda_exec_role_arn

  runtime       = "java21"
  architectures = ["x86_64"]
  handler       = "com.ce.StreamLambdaHandler::handleRequest"
  memory_size   = var.lambda_memory_mb
  timeout       = var.lambda_timeout_seconds

  # reserved_concurrent_executions = var.reserved_concurrency

  # Point directly to your compiled application zip file
  filename         = "${path.module}/ses-email-backend.zip"
  source_code_hash = filebase64sha256("${path.module}/ses-email-backend.zip")

  # Every apply with new code publishes a new version; the alias follows it.
  publish = true

  timeouts {
    create = "20m"
    update = "20m"
  }

  # Encrypts environment variables (and SnapStart snapshots) with the CMK.
  kms_key_arn = var.kms_key_arn

  environment {
    variables = {
      SENDER_EMAIL          = var.sender_email
      RECIPIENT_EMAIL       = var.local_recipient_email
      SES_CONFIGURATION_SET = var.ses_configuration_set
      JAVA_TOOL_OPTIONS     = "-XX:+TieredCompilation -XX:TieredStopAtLevel=1"
    }
  }

  logging_config {
    log_group  = var.log_group_lambda_name
    log_format = "Text"
  }

  tracing_config {
    mode = var.enable_xray ? "Active" : "PassThrough"
  }

  dynamic "snap_start" {
    for_each = var.local_use_snapstart ? [1] : []
    content {
      apply_on = "PublishedVersions"
    }
  }

  # NOTE: If GitHub Actions manages subsequent code deployments, keep ignore_changes.
  # If Terraform manages deployments entirely, you can remove or adjust this block.
  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
    ]
  }

  depends_on = [
    var.iam_role_policy_lambda_kms,
    var.iam_role_policy_lambda_logs,
    var.iam_role_policy_attachment_ses_send,
  ]
}

# API Gateway must invoke the ALIAS, not $LATEST, otherwise SnapStart / provisioned
# concurrency do not apply.
resource "aws_lambda_alias" "live" {
  name             = var.lambda_alias_name
  function_name    = aws_lambda_function.this.function_name
  function_version = aws_lambda_function.this.version
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowInvokeFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  qualifier     = aws_lambda_alias.live.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_lambda_api_execution_arn}/*/*"
}

###############################################################################
# Alternative to SnapStart: provisioned concurrency with Application Auto Scaling
# (cold_start_strategy = "provisioned"). Keep max <= reserved_concurrency.
###############################################################################
resource "aws_lambda_provisioned_concurrency_config" "this" {
  count                             = var.local_use_provisioned ? 1 : 0
  function_name                     = aws_lambda_function.this.function_name
  qualifier                         = aws_lambda_alias.live.name
  provisioned_concurrent_executions = var.provisioned_concurrency_min
}

resource "aws_appautoscaling_target" "lambda" {
  count              = var.local_use_provisioned ? 1 : 0
  service_namespace  = "lambda"
  scalable_dimension = "lambda:function:ProvisionedConcurrency"
  resource_id        = "function:${aws_lambda_function.this.function_name}:${aws_lambda_alias.live.name}"
  min_capacity       = var.provisioned_concurrency_min
  max_capacity       = var.provisioned_concurrency_max

  depends_on = [aws_lambda_provisioned_concurrency_config.this]
}

resource "aws_appautoscaling_policy" "lambda" {
  count              = var.local_use_provisioned ? 1 : 0
  name               = "${var.naming_prefix}-pc-utilization"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.lambda[0].service_namespace
  scalable_dimension = aws_appautoscaling_target.lambda[0].scalable_dimension
  resource_id        = aws_appautoscaling_target.lambda[0].resource_id

  target_tracking_scaling_policy_configuration {
    target_value = var.provisioned_concurrency_target_utilization
    predefined_metric_specification {
      predefined_metric_type = "LambdaProvisionedConcurrencyUtilization"
    }
  }
}
