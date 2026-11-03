#######################################################
# WAF
#######################################################

# Optional WAF: per-IP rate limit + AWS managed common rules
resource "aws_wafv2_web_acl" "api" {
  count = var.enable_waf ? 1 : 0
  name  = "${var.naming_prefix}-api-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "rate-limit-per-ip"
    priority = 1
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit-per-ip"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "aws-common-rules"
    priority = 2
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-common-rules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.naming_prefix}-api-acl"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "api" {
  count        = var.enable_waf ? 1 : 0
  resource_arn = var.rest_api_stage_arn
  web_acl_arn  = aws_wafv2_web_acl.api[0].arn
}
