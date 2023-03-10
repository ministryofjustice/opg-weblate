module "weblate" {
  source = "../../modules/weblate"

  application_log_retention_days  = 30
  ecs_capacity_provider           = "FARGATE_SPOT"
  weblate_repository_url          = "weblate/weblate"
  weblate_container_version       = "latest"
  alb_deletion_protection_enabled = false

  providers = {
    aws.region            = aws.eu_west_1
    aws.global            = aws.global
    aws.management_global = aws.management_global
  }
}
