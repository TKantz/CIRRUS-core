
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_vpc" "application_vpcs" {
  tags = {
    Name = "Application VPC"
  }
}

data "aws_subnet_ids" "subnet_ids" {
  vpc_id = data.aws_vpc.application_vpcs.id

  filter {
    name = "tag:Name"
    values = ["Private application ${data.aws_region.current.name}a subnet",
    "Private application ${data.aws_region.current.name}b subnet"]
  }
}

data "terraform_remote_state" "data_persistence" {
  backend   = "s3"
  config    = local.data_persistence_remote_state_config
  workspace = var.DEPLOY_NAME
}

data "terraform_remote_state" "rds" {
  backend   = "s3"
  config    = local.rds_remote_state_config
  workspace = var.DEPLOY_NAME
}
