module "aurora_serverless_v1_postgres" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-rds-aurora?ref=v7.6.0"

  name              = "${local.name_prefix}-postgresql"
  engine            = "aurora-postgresql"
  engine_mode       = "serverless"
  storage_encrypted = true

  vpc_id                = data.aws_vpc.main.id
  subnets               = data.aws_subnet.data[*].id
  create_security_group = true
  allowed_cidr_blocks   = data.aws_subnet.application[*].cidr_block

  monitoring_interval = 60

  apply_immediately   = true
  skip_final_snapshot = true

  db_parameter_group_name         = aws_db_parameter_group.postgresql.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.postgresql.id
  # enabled_cloudwatch_logs_exports = # NOT SUPPORTED

  scaling_configuration = {
    auto_pause               = true
    min_capacity             = 2
    max_capacity             = 16
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }

  providers = {
    aws = aws.region
   }
}

resource "aws_db_parameter_group" "postgresql" {
  name        = "${local.name_prefix}-aurora-db-postgres-parameter-group"
  family      = "aurora-postgresql10"
  description = "${local.name_prefix}-aurora-db-postgres-parameter-group"
  provider = aws.region
}

resource "aws_rds_cluster_parameter_group" "postgresql" {
  name        = "${local.name_prefix}-aurora-postgres-cluster-parameter-group"
  family      = "aurora-postgresql10"
  description = "${local.name_prefix}-aurora-postgres-cluster-parameter-group"
  provider = aws.region
}
