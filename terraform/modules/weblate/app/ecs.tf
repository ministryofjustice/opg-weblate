resource "aws_ecs_service" "weblate" {
  name                  = "weblate"
  cluster               = var.ecs_cluster
  task_definition       = aws_ecs_task_definition.weblate.arn
  desired_count         = var.ecs_service_desired_count
  platform_version      = "1.4.0"
  wait_for_steady_state = true
  propagate_tags        = "SERVICE"

  capacity_provider_strategy {
    capacity_provider = var.ecs_capacity_provider
    weight            = 100
  }

  network_configuration {
    security_groups  = [aws_security_group.weblate_ecs_service.id]
    subnets          = var.network.application_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.weblate.arn
    container_name   = "weblate"
    container_port   = var.container_port
  }

  lifecycle {
    create_before_destroy = true
  }

  timeouts {
    create = "2m"
    update = "2m"
  }
  provider = aws.region
}

resource "aws_security_group" "weblate_ecs_service" {
  name_prefix = "${local.name_prefix}-ecs-service"
  description = "weblate service security group"
  vpc_id      = var.network.vpc_id
  lifecycle {
    create_before_destroy = true
  }
  provider = aws.region
}

resource "aws_security_group_rule" "weblate_ecs_service_ingress" {
  description              = "Allow Port 80 ingress from the application load balancer"
  type                     = "ingress"
  from_port                = 80
  to_port                  = var.container_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.weblate_ecs_service.id
  source_security_group_id = aws_security_group.weblate_loadbalancer.id
  lifecycle {
    create_before_destroy = true
  }
  provider = aws.region
}

resource "aws_security_group_rule" "weblate_ecs_service_egress" {
  description       = "Allow any egress from service"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr - open egress for ECR access
  security_group_id = aws_security_group.weblate_ecs_service.id
  lifecycle {
    create_before_destroy = true
  }
  provider = aws.region
}

resource "aws_ecs_task_definition" "weblate" {
  family                   = local.name_prefix
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  container_definitions    = "[${local.weblate}]"
  task_role_arn            = var.ecs_task_role.arn
  execution_role_arn       = var.ecs_execution_role.arn
  provider                 = aws.region
}

resource "aws_iam_role_policy" "weblate_task_role" {
  name     = "${data.aws_default_tags.current.tags.environment-name}-weblate-task-role"
  policy   = data.aws_iam_policy_document.task_role_access_policy.json
  role     = var.ecs_task_role.name
  provider = aws.region
}

data "aws_iam_policy_document" "task_role_access_policy" {
  statement {
    sid    = "XrayAccess"
    effect = "Allow"

    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:GetSamplingStatisticSummaries",
    ]

    resources = ["*"]
  }

  provider = aws.region
}


locals {
  weblate = jsonencode(
    {
      cpu                    = 1,
      essential              = true,
      image                  = "${var.weblate_repository_url}:${var.weblate_container_version}",
      mountPoints            = [],
      readonlyRootFilesystem = false
      name                   = "weblate",
      portMappings = [
        {
          containerPort = var.container_port,
          hostPort      = var.container_port,
          protocol      = "tcp"
        }
      ],
      volumesFrom = [],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = var.ecs_application_log_group_name,
          awslogs-region        = data.aws_region.current.name,
          awslogs-stream-prefix = data.aws_default_tags.current.tags.environment-name
        }
      },
      secrets = [
        {
          name      = "WEBLATE_ADMIN_PASSWORD",
          valueFrom = var.app_secrets_arns.weblate_admin_password
      },
        {
          name      = "POSTGRES_PASSWORD",
          valueFrom = var.app_secrets_arns.postgres_password
      },
        {
          name      = "REDIS_PASSWORD",
          valueFrom = var.app_secrets_arns.redis_password
      },
        {
          name      = "WEBLATE_EMAIL_HOST_PASSWORD",
          valueFrom = var.app_secrets_arns.weblate_email_host_password
      }
      ],
      environment = [
        {
          name = "WEBLATE_LOGLEVEL",
          value = tostring(var.app_env_vars.weblate_loglevel)
        },
        {
          name = "WEBLATE_LOGLEVEL_DATABASE",
          value = tostring(var.app_env_vars.weblate_loglevel_database)
        },
        {
          name = "WEBLATE_SITE_TITLE",
          value = tostring(var.app_env_vars.weblate_site_title)
        },
        {
          name = "WEBLATE_SITE_DOMAIN",
          value = tostring(var.app_env_vars.weblate_site_domain)
        },
        {
          name = "WEBLATE_ADMIN_NAME",
          value = tostring(var.app_env_vars.weblate_admin_name)
        },
        {
          name = "WEBLATE_REGISTRATION_OPEN",
          value = tostring(var.app_env_vars.weblate_registration_open)
        },
        {
          name = "WEBLATE_ALLOWED_HOSTS",
          value = tostring(var.app_env_vars.weblate_allowed_hosts)
        },
        {
          name = "WEBLATE_TIME_ZONE",
          value = tostring(var.app_env_vars.weblate_time_zone)
        },
        {
          name = "WEBLATE_ENABLE_HTTPS",
          value = tostring(var.app_env_vars.weblate_enable_https)
        },
        {
          name = "WEBLATE_REQUIRE_LOGIN",
          value = tostring(var.app_env_vars.weblate_require_login)
        },
        {
          name = "WEBLATE_BASIC_LANGUAGES",
          value = tostring(var.app_env_vars.weblate_basic_languages)
        },
        {
          name = "WEBLATE_RATELIMIT_ATTEMPTS",
          value = tostring(var.app_env_vars.weblate_ratelimit_attempts)
        },
        {
          name = "WEBLATE_RATELIMIT_LOCKOUT",
          value = tostring(var.app_env_vars.weblate_ratelimit_lockout)
        },
        {
          name = "WEBLATE_RATELIMIT_WINDOW",
          value = tostring(var.app_env_vars.weblate_ratelimit_window)
        },
        {
          name = "POSTGRES_USER",
          value = tostring(var.app_env_vars.postgres_user)
        },
        {
          name = "POSTGRES_DATABASE",
          value = tostring(var.app_env_vars.postgres_database)
        },
        {
          name = "POSTGRES_HOST",
          value = tostring(var.app_env_vars.postgres_host)
        },
        {
          name = "POSTGRES_PORT",
          value = tostring(var.app_env_vars.postgres_port)
        },
        {
          name = "POSTGRES_SSL_MODE",
          value = tostring(var.app_env_vars.postgres_ssl_mode)
        },
        {
          name = "POSTGRES_ALTER_ROLE",
          value = tostring(var.app_env_vars.postgres_alter_role)
        },
        {
          name = "POSTGRES_CONN_MAX_AGE",
          value = tostring(var.app_env_vars.postgres_conn_max_age)
        },
        {
          name = "REDIS_HOST",
          value = tostring(var.app_env_vars.redis_host)
        },
        {
          name = "REDIS_PORT",
          value = tostring(var.app_env_vars.redis_port)
        },
        {
          name = "REDIS_DB",
          value = tostring(var.app_env_vars.redis_db)
        },
        {
          name = "WEBLATE_EMAIL_HOST",
          value = tostring(var.app_env_vars.weblate_email_host)
        },
        {
          name = "WEBLATE_EMAIL_PORT",
          value = tostring(var.app_env_vars.weblate_email_port)
        },
        {
          name = "WEBLATE_EMAIL_HOST_USER",
          value = tostring(var.app_env_vars.weblate_email_host_user)
        },
        {
          name = "WEBLATE_EMAIL_USE_SSL",
          value = tostring(var.app_env_vars.weblate_email_use_ssl)
        },
        {
          name = "WEBLATE_EMAIL_USE_TLS",
          value = tostring(var.app_env_vars.weblate_email_use_tls)
        },
        {
          name = "WEBLATE_EMAIL_BACKEND",
          value = tostring(var.app_env_vars.weblate_email_backend)
        }
      ]
    }
  )
}
