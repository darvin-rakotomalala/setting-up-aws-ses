#######################################################
# CLOUDWATCH
#######################################################

# Log groups (all KMS-encrypted)
resource "aws_cloudwatch_log_group" "lambda" {
  name              = var.local_log_group_lambda
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

# Application log group from the spec. Lambda writes to ONE log group per function,
# so this one only receives data if the app ships logs to it (e.g. a Logback
# CloudWatch appender). Its metric filters are ready for when it does.
resource "aws_cloudwatch_log_group" "app" {
  name              = var.local_log_group_app
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

resource "aws_cloudwatch_log_group" "api" {
  name              = var.local_log_group_api
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

locals {
  custom_ns = "${var.project_name}/${var.environment}"
}

###############################################################################
# Metric filters - Lambda log group
# The function logs in Text format, so patterns are text patterns.
###############################################################################
resource "aws_cloudwatch_log_metric_filter" "lambda" {
  for_each = {
    LambdaTimeouts    = "\"Task timed out after\""
    LambdaOutOfMemory = "?\"OutOfMemoryError\" ?\"Runtime.OutOfMemory\" ?\"Out of memory\""
    LambdaExceptions  = "?\"ERROR\" ?\"Error\" ?\"Exception\" ?\"Unhandled\" ?\"panic\""
    # Without SnapStart the REPORT line has "Init Duration"; with SnapStart it has
    # "Restore Duration" instead. Both are tracked.
    LambdaColdStarts        = "\"Init Duration\""
    LambdaSnapStartRestores = "\"Restore Duration\""
  }

  name           = each.key
  log_group_name = aws_cloudwatch_log_group.lambda.name
  pattern        = each.value

  metric_transformation {
    name          = each.key
    namespace     = local.custom_ns
    value         = "1"
    default_value = "0"
  }
}

###############################################################################
# Metric filters - Spring Boot application log group
###############################################################################
resource "aws_cloudwatch_log_metric_filter" "app" {
  for_each = {
    AppErrors   = "\"ERROR\""
    AppWarnings = "\"WARN\""
  }

  name           = each.key
  log_group_name = aws_cloudwatch_log_group.app.name
  pattern        = each.value

  metric_transformation {
    name          = each.key
    namespace     = local.custom_ns
    value         = "1"
    default_value = "0"
  }
}

###############################################################################
# Metric filters - API Gateway access logs (JSON)
###############################################################################
resource "aws_cloudwatch_log_metric_filter" "api" {
  for_each = {
    ApiThrottled     = "{ $.status = 429 }"
    ApiSevereLatency = "{ $.responseLatency > ${var.api_latency_threshold_ms * 2} }"
  }

  name           = each.key
  log_group_name = aws_cloudwatch_log_group.api.name
  pattern        = each.value

  metric_transformation {
    name          = each.key
    namespace     = local.custom_ns
    value         = "1"
    default_value = "0"
  }
}

# 4xx/5xx by endpoint. A metric dimension per path creates one custom metric per
# distinct path; fine for a small API, costly for APIs with ID-style paths.
resource "aws_cloudwatch_log_metric_filter" "api_errors_by_path" {
  name           = "ApiErrorsByPath"
  log_group_name = aws_cloudwatch_log_group.api.name
  pattern        = "{ $.status >= 400 }"

  metric_transformation {
    name      = "ApiErrorsByPath"
    namespace = local.custom_ns
    value     = "1"
    dimensions = {
      Path   = "$.path"
      Status = "$.status"
    }
  }
}

###############################################################################
# Alarms
###############################################################################
locals {
  lambda_dims = jsonencode({ FunctionName = var.lambda_function_name })
  api_dims    = jsonencode({ ApiName = var.java_lambda_api_name, Stage = var.java_lambda_api_stage_name })
  no_dims     = jsonencode({})

  alarms = {
    # ---- Lambda -------------------------------------------------------------
    lambda-errors = {
      namespace   = "AWS/Lambda", metric = "Errors", dims = local.lambda_dims
      statistic   = "Sum", extended_statistic = null, threshold = 1, severity = "critical"
      description = "Lambda invocation errors (code exceptions, crashes)."
    }
    lambda-throttles = {
      namespace   = "AWS/Lambda", metric = "Throttles", dims = local.lambda_dims
      statistic   = "Sum", extended_statistic = null, threshold = 1, severity = "warning"
      description = "Lambda hit its reserved/account concurrency limit."
    }
    /*
    lambda-concurrency = {
      namespace   = "AWS/Lambda", metric = "ConcurrentExecutions", dims = local.lambda_dims
      statistic   = "Maximum", extended_statistic = null
      threshold   = max(1, floor(var.reserved_concurrency * 0.8)), severity = "warning"
      description = "Concurrency above 80% of reserved concurrency."
    }
    */
    lambda-duration-p95 = {
      namespace   = "AWS/Lambda", metric = "Duration", dims = local.lambda_dims
      statistic   = null, extended_statistic = "p95"
      threshold   = var.lambda_duration_threshold_ms, severity = "warning"
      description = "High p95 duration: performance bottleneck or imminent timeouts."
    }
    lambda-timeouts = {
      namespace   = local.custom_ns, metric = "LambdaTimeouts", dims = local.no_dims
      statistic   = "Sum", extended_statistic = null, threshold = 1, severity = "critical"
      description = "Function timed out (\"Task timed out after\")."
    }
    lambda-out-of-memory = {
      namespace   = local.custom_ns, metric = "LambdaOutOfMemory", dims = local.no_dims
      statistic   = "Sum", extended_statistic = null, threshold = 1, severity = "critical"
      description = "Out-of-memory errors. Raise lambda_memory_mb."
    }
    lambda-exceptions = {
      namespace   = local.custom_ns, metric = "LambdaExceptions", dims = local.no_dims
      statistic   = "Sum", extended_statistic = null, threshold = 5, severity = "warning"
      description = "Unhandled exceptions / ERROR lines in the Lambda log group."
    }

    # ---- API Gateway ---------------------------------------------------------
    api-5xx = {
      namespace   = "AWS/ApiGateway", metric = "5XXError", dims = local.api_dims
      statistic   = "Sum", extended_statistic = null, threshold = var.api_5xx_threshold, severity = "critical"
      description = "High 5xx rate. Route this topic to PagerDuty / OpsGenie."
    }
    api-4xx = {
      namespace   = "AWS/ApiGateway", metric = "4XXError", dims = local.api_dims
      statistic   = "Sum", extended_statistic = null, threshold = var.api_4xx_threshold, severity = "warning"
      description = "Spike in 4xx client errors (bad input, scanners, bots)."
    }
    api-latency-p95 = {
      namespace   = "AWS/ApiGateway", metric = "Latency", dims = local.api_dims
      statistic   = null, extended_statistic = "p95"
      threshold   = var.api_latency_threshold_ms, severity = "warning"
      description = "High overall API latency."
    }
    api-integration-latency-p95 = {
      namespace   = "AWS/ApiGateway", metric = "IntegrationLatency", dims = local.api_dims
      statistic   = null, extended_statistic = "p95"
      threshold   = var.api_integration_latency_threshold_ms, severity = "warning"
      description = "High integration latency: backend dependency issue (Lambda / SES)."
    }
    api-throttling = {
      namespace   = local.custom_ns, metric = "ApiThrottled", dims = local.no_dims
      statistic   = "Sum", extended_statistic = null, threshold = 1, severity = "warning"
      description = "API Gateway returned 429: stage/method rate limits reached."
    }
    api-severe-latency = {
      namespace   = local.custom_ns, metric = "ApiSevereLatency", dims = local.no_dims
      statistic   = "Sum", extended_statistic = null, threshold = 3, severity = "warning"
      description = "Several requests slower than 2x the latency threshold."
    }

    # ---- SES ----------------------------------------------------------------
    ses-bounce-rate = {
      namespace   = "AWS/SES", metric = "Reputation.BounceRate", dims = local.no_dims
      statistic   = "Average", extended_statistic = null, threshold = 0.05, severity = "critical"
      description = "SES bounce rate >= 5% (account is put under review at 5%, paused at 10%)."
    }
    ses-complaint-rate = {
      namespace   = "AWS/SES", metric = "Reputation.ComplaintRate", dims = local.no_dims
      statistic   = "Average", extended_statistic = null, threshold = 0.001, severity = "critical"
      description = "SES complaint rate >= 0.1% (review threshold)."
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = local.alarms

  alarm_name          = "${var.naming_prefix}-${each.key}"
  alarm_description   = each.value.description
  namespace           = each.value.namespace
  metric_name         = each.value.metric
  dimensions          = jsondecode(each.value.dims)
  statistic           = each.value.statistic
  extended_statistic  = each.value.extended_statistic
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = each.value.threshold
  period              = 300
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [var.alert_topic_arns[each.value.severity]]
  # ok_actions    = [aws_sns_topic.alerts[each.value.severity].arn]
}
