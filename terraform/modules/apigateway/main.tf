#######################################################
# API GATEWAY
# REST API:  /{proxy+}  ANY  ->  Lambda proxy integration (alias)
#######################################################

resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = "Contact form API (Spring Boot on Lambda, sends mail through SES)"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "{proxy+}"
}

# Public contact form: no authorizer. Abuse is limited by throttling (+ optional WAF),
# input validation in Spring, and the SES identity/quota. Add an API key, Cognito or
# Lambda authorizer here if the API is not meant to be public.
resource "aws_api_gateway_method" "proxy_any" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy_any.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_alias_invoke_arn
  timeout_milliseconds    = 29000
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  # New deployment whenever the API definition changes.
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy_any.id,
      aws_api_gateway_method.proxy_any.authorization,
      aws_api_gateway_integration.lambda.id,
      aws_api_gateway_integration.lambda.uri,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  # status and responseLatency are numeric so metric filters can compare them.
  # errorMessage uses messageString, which API Gateway already renders as a quoted,
  # escaped JSON string. integrationLatency is quoted because API Gateway prints "-" when the backend
  # was never called (e.g. throttled requests), which would break the JSON.
  api_access_log_format = join("", [
    "{",
    "\"requestId\":\"$context.requestId\",",
    "\"ip\":\"$context.identity.sourceIp\",",
    "\"requestTime\":\"$context.requestTime\",",
    "\"httpMethod\":\"$context.httpMethod\",",
    "\"path\":\"$context.path\",",
    "\"status\":$context.status,",
    "\"responseLatency\":$context.responseLatency,",
    "\"integrationLatency\":\"$context.integrationLatency\",",
    "\"integrationStatus\":\"$context.integrationStatus\",",
    "\"errorMessage\":$context.error.messageString",
    "}",
  ])
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = var.api_stage_name

  xray_tracing_enabled  = var.enable_xray
  cache_cluster_enabled = var.enable_api_cache
  cache_cluster_size    = var.enable_api_cache ? var.api_cache_size_gb : null

  access_log_settings {
    destination_arn = var.log_group_api_arn
    format          = local.api_access_log_format
  }

  depends_on = [var.api_gateway_account_id]
}

# Stage-wide defaults + detailed execution metrics
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    logging_level          = "OFF" # access logs (KMS-encrypted) are used instead
    data_trace_enabled     = false # never log request bodies (PII)
    throttling_rate_limit  = var.api_throttle_rate
    throttling_burst_limit = var.api_throttle_burst
    caching_enabled        = var.enable_api_cache
    cache_ttl_in_seconds   = var.api_cache_ttl_seconds
    cache_data_encrypted   = true
  }
}

# Tighter limit on the proxy method itself
resource "aws_api_gateway_method_settings" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    throttling_rate_limit  = var.api_method_throttle_rate
    throttling_burst_limit = var.api_method_throttle_burst
  }

  depends_on = [aws_api_gateway_method_settings.all]
}
