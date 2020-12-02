terraform {
  required_providers {
    aws  = ">= 2.31.0"
    null = "~> 2.1"
  }
  backend "s3" {
  }
}

provider "aws" {
  version = ">= 3.19.0"
  source = "hashicorp/aws"
  ignore_tags {
    key_prefixes = ["gsfc-ngap"]
  }
}

locals {
  prefix = "${var.DEPLOY_NAME}-cumulus-${var.MATURITY}"

  buckets = data.terraform_remote_state.daac.outputs.bucket_map

  bucket_map_key = data.terraform_remote_state.daac.outputs.bucket_map_key == "" ? null : data.terraform_remote_state.daac.outputs.bucket_map_key

  protected_bucket_names = [for k, v in local.buckets : v.name if v.type == "protected"]
  public_bucket_names    = [for k, v in local.buckets : v.name if v.type == "public"]

  tea_stack_name              = "${local.prefix}-thin-egress-app"
  tea_stage_name              = var.MATURITY
  thin_egress_jwt_secret_name = "${local.prefix}-jwt_secret_for_tea"

  permissions_boundary_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/NGAPShRoleBoundary"

  daac_remote_state_config = {
    bucket = "${var.DEPLOY_NAME}-cumulus-${var.MATURITY}-tf-state-${substr(data.aws_caller_identity.current.account_id, -4, 4)}"
    key    = "daac/terraform.tfstate"
    region = "${data.aws_region.current.name}"
  }

  data_persistence_remote_state_config = {
    bucket = "${var.DEPLOY_NAME}-cumulus-${var.MATURITY}-tf-state-${substr(data.aws_caller_identity.current.account_id, -4, 4)}"
    key    = "data-persistence/terraform.tfstate"
    region = "${data.aws_region.current.name}"
  }

  system_bucket = "${var.DEPLOY_NAME}-cumulus-${var.MATURITY}-internal"

  cmr_client_id = "${var.DEPLOY_NAME}-cumulus-${var.MATURITY}"

  default_tags = {
    Deployment = "${var.DEPLOY_NAME}-cumulus-${var.MATURITY}"
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_vpc" "application_vpcs" {
  tags = {
    Name = "Application VPC"
  }
}

data "aws_subnet_ids" "subnet_ids" {
  vpc_id = data.aws_vpc.application_vpcs.id

  tags = {
    Name = "Private application ${data.aws_region.current.name}a subnet"
  }
}

data "terraform_remote_state" "daac" {
  backend   = "s3"
  workspace = "${var.DEPLOY_NAME}"
  config    = local.daac_remote_state_config
}

data "terraform_remote_state" "data_persistence" {
  backend   = "s3"
  workspace = "${var.DEPLOY_NAME}"
  config    = local.data_persistence_remote_state_config
}