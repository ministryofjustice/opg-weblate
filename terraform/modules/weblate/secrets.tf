locals {
  app_secrets = [
    "weblate_admin_password",
    "postgres_password",
    "redis_password",
    "weblate_email_host_password",
  ]
  shared_secrets = [
    "weblate_admin_email",
    "weblate_github",
    "weblate_gpg_identity",
    "weblate_social_auth_github",
  ]
}

resource "aws_secretsmanager_secret" "app_secrets" {
  for_each                = toset(local.app_secrets)
  name                    = "new-${local.name_prefix}/${each.key}"
  recovery_window_in_days = 0
  provider                = aws.region
}

resource "random_password" "app_secrets" {
  for_each = toset(local.app_secrets)
  length   = 32
  special  = false
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  for_each      = toset(local.app_secrets)
  secret_id     = aws_secretsmanager_secret.app_secrets[each.key].name
  secret_string = random_password.app_secrets[each.key].result
  lifecycle {
    ignore_changes = [
      secret_string,
    ]
  }
  provider = aws.region
}

data "aws_secretsmanager_secret" "shared_secrets" {
  for_each = toset(local.shared_secrets)
  name     = "new-${data.aws_default_tags.current.tags.application}-${data.aws_default_tags.current.tags.account-name}-${data.aws_region.current.name}/${each.key}"
  provider = aws.region
}
