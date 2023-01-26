variable "environments" {
  type = map(
    object({
      account_id        = string
      account_name      = string
      is_production     = bool
      container_version = string
      }
    )
  )
}

locals {
  environment_name = lower(replace(terraform.workspace, "_", "-"))
  environment      = contains(keys(var.environments), local.environment_name) ? var.environments[local.environment_name] : var.environments["default"]

  mandatory_moj_tags = {
    business-unit    = "OPG"
    application      = "opg-weblate"
    environment-name = local.environment_name
    owner            = "OPG Webops: opgteam+weblate@digital.justice.gov.uk"
    is-production    = local.environment.is_production
    runbook          = "https://github.com/ministryofjustice/opg-weblate"
    source-code      = "https://github.com/ministryofjustice/opg-weblate"
  }

  optional_tags = {
    infrastructure-support = "OPG Webops: opgteam+opg-weblate@digital.justice.gov.uk"
    account-name           = local.environment.account_name
  }

  default_tags = merge(local.mandatory_moj_tags, local.optional_tags)
}
