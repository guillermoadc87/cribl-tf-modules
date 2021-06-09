locals {
  module = "bucket"
}

module "label" {
  source = "../../child-modules/label"
  module = local.module
  app    = var.app
  stage  = var.stage
}

resource "aws_s3_bucket" "bucket" {
  bucket = module.label.name
  acl    = "private"

  tags = module.label.tags
}

resource "aws_s3_bucket_policy" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.bucket.json
}

data "aws_iam_policy_document" "bucket" {
  statement {
    sid = "AllowSSLRequestsOnly"
    principals {
      identifiers = ["*"]
      type        = "*"
    }
    actions = [
      "s3:*",
    ]
    effect = "Deny"
    condition {
      test     = "Bool"
      values   = [false]
      variable = "aws:SecureTransport"
    }
    resources = [
      aws_s3_bucket.bucket.arn,
      "${aws_s3_bucket.bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "access_bucket" {
  statement {
    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:Head*",
      "s3:Put*",
    ]

    resources = [
      aws_s3_bucket.bucket.arn,
      "${aws_s3_bucket.bucket.arn}/*",
    ]

    effect = "Allow"
  }
}

resource "aws_iam_policy" "access_bucket" {
  name   = module.label.name
  path   = "/"
  policy = data.aws_iam_policy_document.access_bucket.json
}