variable "account_id" {
  type = string
}

variable "is_production" {
  type = bool
}

variable "container_version" {
  type = string

}
variable "account_name" {
  type = string
}


locals {
  environment_name = "production"

  mandatory_moj_tags = {
    business-unit    = "OPG"
    application      = "opg-weblate"
    environment-name = local.environment_name
    owner            = "OPG Webops: opgteam+weblate@digital.justice.gov.uk"
    is-production    = var.is_production
    runbook          = "https://github.com/ministryofjustice/opg-weblate"
    source-code      = "https://github.com/ministryofjustice/opg-weblate"
  }

  optional_tags = {
    infrastructure-support = "OPG Webops: opgteam+opg-weblate@digital.justice.gov.uk"
    account-name           = var.account_name
  }

  default_tags = merge(local.mandatory_moj_tags, local.optional_tags)
}
