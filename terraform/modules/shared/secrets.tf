locals {
  shared_secrets = [
    "weblate_admin_email",
    "weblate_github",
    "weblate_gpg_identity",
    "weblate_social_auth_github",
  ]
}

resource "aws_secretsmanager_secret" "shared_secrets" {
  for_each                = toset(local.shared_secrets)
  name                    = "new-${local.name_prefix}/${each.key}"
  recovery_window_in_days = 0
  provider                = aws.region
}

resource "aws_secretsmanager_secret_version" "shared_secrets" {
  for_each      = toset(local.shared_secrets)
  secret_id     = aws_secretsmanager_secret.shared_secrets[each.key].name
  secret_string = "default"
  lifecycle {
    ignore_changes = [
      secret_string,
    ]
  }
  provider = aws.region
}
