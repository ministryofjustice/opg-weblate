module "aurora_serverless_v1_postgres" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-rds-aurora?ref=v7.6.0"

  name              = "${local.name_prefix}-postgresql"
  engine            = "aurora-postgresql"
  engine_mode       = "serverless"
  engine_version    = "11.13"
  storage_encrypted = true

  vpc_id                = data.aws_vpc.main.id
  subnets               = data.aws_subnet.data[*].id
  create_security_group = true
  allowed_cidr_blocks   = data.aws_subnet.application[*].cidr_block

  monitoring_interval = 60

  apply_immediately    = true
  skip_final_snapshot  = true
  enable_http_endpoint = true

  db_parameter_group_name = "default.aurora-postgresql11"
  create_random_password  = false
  master_password         = aws_secretsmanager_secret_version.app_secrets["postgres_password"].secret_string
  master_username         = "root"
  database_name           = "weblate"
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
