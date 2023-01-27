data "aws_route53_zone" "weblate" {
  provider = aws.management
  name     = "weblate.opg.service.justice.gov.uk"
}

locals {
  dev_wildcard = data.aws_default_tags.current.tags.is-production ? "" : "*."
}

resource "aws_acm_certificate" "weblate" {
  provider          = aws.region
  domain_name       = "${local.dev_wildcard}weblate.opg.service.justice.gov.uk"
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "weblate" {
  provider                = aws.region
  certificate_arn         = aws_acm_certificate.weblate.arn
  validation_record_fqdns = [for record in aws_route53_record.certificate_validation_weblate : record.fqdn]
}

resource "aws_route53_record" "certificate_validation_weblate" {
  provider = aws.management
  for_each = {
    for dvo in aws_acm_certificate.weblate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.weblate.zone_id
}
