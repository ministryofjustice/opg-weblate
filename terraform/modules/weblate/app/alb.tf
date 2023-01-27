resource "aws_lb_target_group" "weblate" {
  name                 = "${data.aws_default_tags.current.tags.environment-name}-weblate"
  port                 = 80
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.network.vpc_id
  deregistration_delay = 0
  depends_on           = [aws_lb.weblate]

  health_check {
    enabled = true
    path    = "/healthz/"
  }

  provider = aws.region
}

resource "aws_lb" "weblate" {
  name                       = "${data.aws_default_tags.current.tags.environment-name}-weblate"
  internal                   = false #tfsec:ignore:AWS005 - public alb
  load_balancer_type         = "application"
  drop_invalid_header_fields = true
  subnets                    = var.network.public_subnets
  enable_deletion_protection = var.alb_deletion_protection_enabled
  security_groups            = [aws_security_group.weblate_loadbalancer.id]

  provider = aws.region
}

resource "aws_lb_listener" "weblate_loadbalancer_http_redirect" {
  load_balancer_arn = aws_lb.weblate.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  provider = aws.region
}

locals {
  dev_wildcard = data.aws_default_tags.current.tags.is-production ? "" : "*."
  dev_app_fqdn = "${local.name_prefix}.weblate.opg.service.justice.gov.uk"
}

data "aws_acm_certificate" "weblate" {
  domain   = "${local.dev_wildcard}weblate.opg.service.justice.gov.uk"
  provider = aws.region
}

resource "aws_lb_listener" "weblate_loadbalancer" {
  load_balancer_arn = aws_lb.weblate.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-2019-08"
  certificate_arn   = data.aws_acm_certificate.weblate.arn

  default_action {
    target_group_arn = aws_lb_target_group.weblate.arn
    type             = "forward"
  }
  provider = aws.region
}

resource "aws_lb_listener_certificate" "weblate_loadbalancer_live_service_certificate" {
  listener_arn    = aws_lb_listener.weblate_loadbalancer.arn
  certificate_arn = data.aws_acm_certificate.weblate.arn
  provider        = aws.region
}

resource "aws_security_group" "weblate_loadbalancer" {
  name_prefix = "${data.aws_default_tags.current.tags.environment-name}-weblate-loadbalancer"
  description = "weblate service application load balancer"
  vpc_id      = var.network.vpc_id
  lifecycle {
    create_before_destroy = true
  }
  provider = aws.region
}

resource "aws_security_group_rule" "weblate_loadbalancer_port_80_redirect_ingress" {
  description       = "Port 80 ingress for redirection to port 443"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.ingress_allow_list_cidr #tfsec:ignore:aws-vpc-no-public-ingress-sgr
  security_group_id = aws_security_group.weblate_loadbalancer.id
  provider          = aws.region
}

resource "aws_security_group_rule" "weblate_loadbalancer_ingress" {
  description       = "Port 443 ingress from the allow list to the application load balancer"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.ingress_allow_list_cidr #tfsec:ignore:aws-vpc-no-public-ingress-sgr
  security_group_id = aws_security_group.weblate_loadbalancer.id
  provider          = aws.region
}

resource "aws_security_group_rule" "weblate_loadbalancer_egress" {
  description       = "Allow any egress from service load balancer"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr - open egress for load balancers
  security_group_id = aws_security_group.weblate_loadbalancer.id
  provider          = aws.region
}
