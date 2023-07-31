module "data_migration1" {
  source = "https://github.com/nasa/cumulus/releases/download/v16.0.0/terraform-aws-cumulus-data-migrations1.zip"

  prefix = local.prefix

  permissions_boundary_arn = local.permissions_boundary_arn

  vpc_id            = data.aws_vpc.application_vpcs.id
  lambda_subnet_ids = data.aws_subnet_ids.subnet_ids.ids

  dynamo_tables = data.terraform_remote_state.data_persistence.outputs.dynamo_tables

  rds_security_group_id      = data.terraform_remote_state.rds.outputs.rds_security_group_id
  rds_user_access_secret_arn = data.terraform_remote_state.rds.outputs.rds_user_access_secret_arn
  rds_connection_heartbeat   = var.rds_connection_heartbeat

  provider_kms_key_id = var.provider_kms_key_id

  tags = merge(var.tags, local.default_tags)
}
