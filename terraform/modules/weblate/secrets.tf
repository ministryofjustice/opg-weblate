locals {
  app_secrets = [
    "weblate_admin_password",
    "postgres_password",
    "redis_password",
    "weblate_email_host_password",
  ]
  shared_secrets = [
    "weblate_admin_email",
    "weblate_github_username",
    "weblate_github_token",
    "weblate_github_host",
    "weblate_gpg_identity",
    "weblate_social_auth_github_key",
    "weblate_social_auth_github_secret",
    "weblate_social_auth_github_org_key",
    "weblate_social_auth_github_org_secret",
    "weblate_social_auth_github_org_name",
    "weblate_social_auth_github_team_key",
    "weblate_social_auth_github_team_secret",
    "weblate_social_auth_github_team_id",
  ]
}

resource "aws_secretsmanager_secret" "app_secrets" {
  for_each = toset(local.app_secrets)
  name       = "${local.name_prefix}-${each.key}"
  provider = aws.region
}

resource "random_password" "app_secrets" {
  for_each = toset(local.app_secrets)
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  for_each = toset(local.app_secrets)
  secret_id     = aws_secretsmanager_secret.app_secrets[each.key].name
  secret_string = random_password.app_secrets[each.key].result
  lifecycle {
    ignore_changes = [
      secret_string,
    ]
  }
  provider = aws.region
}






# data "aws_secretsmanager_secret_version" "shared_secrets" {
#   for_each = to_set(local.shared_secrets)
#   secret_id = each.key
#   provider = aws.region
# }
