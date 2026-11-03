#######################################################
# S3
#######################################################

# Artifacts bucket for the Lambda deployment package

resource "aws_s3_bucket" "lambda_artifacts" {
  bucket_prefix = "${var.naming_prefix}-lambda-artifacts-69127"
  force_destroy = true
  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-lambda-artifacts"
  })
}

resource "aws_s3_bucket_public_access_block" "lambda_artifacts" {
  bucket                  = aws_s3_bucket.lambda_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "artifacts" {
  bucket = aws_s3_bucket.lambda_artifacts.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.lambda_artifacts.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.lambda_artifacts.id

  rule {
    id     = "expire-old-packages"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "artifacts" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.lambda_artifacts.arn, "${aws_s3_bucket.lambda_artifacts.arn}/*"]
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

resource "aws_s3_bucket_policy" "artifacts" {
  bucket     = aws_s3_bucket.lambda_artifacts.id
  policy     = data.aws_iam_policy_document.artifacts.json
  depends_on = [aws_s3_bucket_public_access_block.lambda_artifacts]
}
