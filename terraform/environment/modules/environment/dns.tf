data "aws_route53_zone" "weblate_lpa" {
  provider = aws.management_global
  name     = "weblate.opg.service.justice.gov.uk"
}

locals {
  dns_namespace_for_environment = data.aws_default_tags.current.tags.environment-name == "production" ? "" : "${data.aws_default_tags.current.tags.environment-name}."
}

resource "aws_route53_record" "app" {
  # weblate.opg.service.justice.gov.uk
  provider = aws.management_global
  zone_id  = data.aws_route53_zone.weblate_lpa.zone_id
  name     = "${local.dns_namespace_for_environment}${data.aws_route53_zone.weblate_lpa.name}"
  type     = "A"

  alias {
    evaluate_target_health = false
    name                   = module.app.load_balancer.dns_name
    zone_id                = module.app.load_balancer.zone_id
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "app_fqdn" {
  value = aws_route53_record.app.fqdn
}
