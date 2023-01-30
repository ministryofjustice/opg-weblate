locals {

  mandatory_moj_tags = {
    business-unit    = "OPG"
    application      = "opg-weblate"
    environment-name = "production"
    owner            = "OPG Webops: opgteam+weblate@digital.justice.gov.uk"
    is-production    = true
    runbook          = "https://github.com/ministryofjustice/opg-weblate"
    source-code      = "https://github.com/ministryofjustice/opg-weblate"
  }

  optional_tags = {
    infrastructure-support = "OPG Webops: opgteam+opg-weblate@digital.justice.gov.uk"
    account-name           = "development"
  }

  default_tags = merge(local.mandatory_moj_tags, local.optional_tags)
}
