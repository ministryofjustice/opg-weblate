module "eu_west_1" {
  source = "../modules/environment"

  application_log_retention_days  = 30
  ecs_capacity_provider           = "FARGATE_SPOT"
  weblate_repository_url          = "weblate/weblate"
  weblate_container_version       = var.container_version
  alb_deletion_protection_enabled = true
  app_env_vars = {
    app_public_url = "",
  }
  providers = {
    aws.region            = aws.eu_west_1
    aws.global            = aws.global
    aws.management_global = aws.management_global
  }
}
