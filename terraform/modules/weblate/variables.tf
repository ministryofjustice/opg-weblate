locals {
  name_prefix = "${data.aws_default_tags.current.tags.application}-${data.aws_default_tags.current.tags.environment-name}-${data.aws_region.current.name}"

  weblate_docker_configuration = {
    weblate_loglevel          = "DEBUG"
    weblate_loglevel_database = "DEBUG"
    weblate_site_title        = "OPG Weblate"
    weblate_site_domain       = aws_route53_record.app.fqdn
    weblate_admin_name        = "opg-weblate"
    weblate_registration_open = 0
    weblate_allowed_hosts     = aws_route53_record.app.fqdn
    weblate_time_zone         = "Europe/London"
    weblate_enable_https      = 1
    weblate_require_login     = 0
    # weblate_basic_languages = "" # This only limits non privileged users to add unwanted languages. The project admins are still presented with full selection of languages defined in Weblate.
    weblate_ratelimit_attempts           = 5
    weblate_ratelimit_lockout            = 300
    weblate_ratelimit_window             = 600
    postgres_user                        = module.aurora_serverless_v1_postgres.cluster_master_username
    postgres_host                        = module.aurora_serverless_v1_postgres.cluster_endpoint
    postgres_port                        = module.aurora_serverless_v1_postgres.cluster_port
    postgres_database                    = module.aurora_serverless_v1_postgres.cluster_database_name
    postgres_ssl_mode                    = "require"
    postgres_alter_role                  = "weblate"
    postgres_conn_max_age                = 3600
    postgres_disable_server_side_cursors = 1
    redis_host                           = data.aws_elasticache_replication_group.weblate_cache.primary_endpoint_address
    redis_port                           = 6379
    redis_db                             = 1
    redis_tls                            = 1
    redis_verify_ssl                     = 1
    weblate_email_backend                = "django.core.mail.backends.dummy.EmailBackend" # "django.core.mail.backends.smtp.EmailBackend". To disable sending e-mails by Weblate set EMAIL_BACKEND to django.core.mail.backends.dummy.EmailBackend. see https://docs.weblate.org/en/latest/admin/install.html#production-email
    weblate_email_host                   = "smtp.example.com"
    weblate_email_port                   = 587 # 587 = STARTTLS, 465 = TLS Wrapper see https://docs.aws.amazon.com/ses/latest/dg/smtp-connect.html
    weblate_email_host_user              = "user"
    weblate_email_use_ssl                = 1 # one or other of these are set in ecs container definition
    weblate_email_use_tls                = 1 # one or other of these are set in ecs container definition
  }
}

variable "application_log_retention_days" {
  type        = number
  description = "Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire."
}

variable "ecs_capacity_provider" {
  type        = string
  description = "Name of the capacity provider to use. Valid values are FARGATE_SPOT and FARGATE"
}

variable "weblate_repository_url" {
  type        = string
  description = "(optional) describe your variable"
}

variable "weblate_container_version" {
  type        = string
  description = "(optional) describe your variable"
}

variable "alb_deletion_protection_enabled" {
  type        = bool
  description = "If true, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer. Defaults to false."
}

variable "ecs_service_desired_count" {
  type        = number
  description = "The number of instances of the task definition to place and keep running."
  default     = 0
}
