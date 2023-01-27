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
    create = "7m"
    update = "7m"
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
      readonlyRootFilesystem = true
      name                   = "app",
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
      environment = [
        {
          name  = "LOGGING_LEVEL",
          value = tostring(100)
        },
        {
          name  = "APP_PORT",
          value = tostring(var.container_port)
        }
      ]
    }
  )
}
