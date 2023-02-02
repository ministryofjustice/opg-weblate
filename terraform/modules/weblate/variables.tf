locals {
  name_prefix = "${data.aws_default_tags.current.tags.application}-${data.aws_default_tags.current.tags.environment-name}-${data.aws_region.current.name}"

  weblate_docker_configuration = {
    weblate_loglevel = ""
    weblate_loglevel_database = ""
    weblate_site_title = "OPG Weblate"
    weblate_site_domain = aws_route53_record.app.fqdn
    weblate_admin_name = "opg-weblate"
    weblate_registration_open = 0
    weblate_allowed_hosts = ""
    weblate_time_zone = "Europe/London"
    weblate_enable_https = 1
    weblate_require_login = ""
    weblate_basic_languages = ""
    weblate_ratelimit_attempts = ""
    weblate_ratelimit_lockout = ""
    weblate_ratelimit_window = ""
    postgres_user = module.aurora_serverless_v1_postgres.cluster_master_username
    postgres_host = module.aurora_serverless_v1_postgres.cluster_endpoint
    postgres_port = module.aurora_serverless_v1_postgres.cluster_port
    postgres_database = module.aurora_serverless_v1_postgres.cluster_database_name
    postgres_ssl_mode = "require"
    postgres_alter_role = "weblate"
    postgres_conn_max_age = 3600
    postgres_disable_server_side_cursors = 1
    redis_host = ""
    redis_port = ""
    redis_db = ""
    weblate_email_host = ""
    weblate_email_port = ""
    weblate_email_host_user = ""
    weblate_email_use_ssl = ""
    weblate_email_use_tls = ""
    weblate_email_backend = ""
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
