terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  ignore_tags {
    key_prefixes = ["gsfc-ngap"]
  }
}

data "aws_caller_identity" "current" {}

locals {
  cumulus-prefix       = "${var.DEPLOY_NAME}-cumulus-${var.MATURITY}"
  aws_account_id       = data.aws_caller_identity.current.account_id
  aws_account_id_last4 = substr(data.aws_caller_identity.current.account_id, -4, 4)
  default_tags = {
    Deployment = "${var.DEPLOY_NAME}-cumulus-${var.MATURITY}"
  }
}

resource "aws_s3_bucket" "backend-tf-state-bucket" {
  bucket = "${local.cumulus-prefix}-tf-state-${local.aws_account_id_last4}"
  lifecycle {
    prevent_destroy = true
  }
  tags = local.default_tags
}

resource "aws_s3_bucket_versioning" "backend-tf-state-bucket-versioning" {
  bucket = aws_s3_bucket.backend-tf-state-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "backend-tf-locks-table" {
  name         = "${local.cumulus-prefix}-tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  lifecycle {
    prevent_destroy = true
  }
  tags = local.default_tags
}
