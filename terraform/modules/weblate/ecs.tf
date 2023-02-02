resource "aws_ecs_cluster" "main" {
  name = local.name_prefix
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  provider = aws.region
}

module "allow_list" {
  source = "git@github.com:ministryofjustice/opg-terraform-aws-moj-ip-allow-list.git?ref=v1.7.1"
}

module "application_logs" {
  source                         = "./application_logs"
  application_log_retention_days = var.application_log_retention_days
  providers = {
    aws.region = aws.region
  }
}

module "app" {
  source                         = "./app"
  ecs_cluster                    = aws_ecs_cluster.main.id
  ecs_execution_role             = aws_iam_role.execution_role
  ecs_task_role                  = aws_iam_role.app_task_role
  ecs_service_desired_count      = 0
  ecs_application_log_group_name = module.application_logs.cloudwatch_log_group.name
  ecs_capacity_provider          = var.ecs_capacity_provider
  app_env_vars                   =                  local.weblate_docker_configuration
  weblate_repository_url          = var.weblate_repository_url
  weblate_container_version       = var.weblate_container_version
  ingress_allow_list_cidr         = module.allow_list.moj_sites
  alb_deletion_protection_enabled = var.alb_deletion_protection_enabled
  container_port                  = 8080
  network = {
    vpc_id              = data.aws_vpc.main.id
    application_subnets = data.aws_subnet.application.*.id
    public_subnets      = data.aws_subnet.public.*.id
  }
  providers = {
    aws.region = aws.region
  }
}
