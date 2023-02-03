resource "aws_security_group" "weblate_cache" {
  provider    = aws.region
  name_prefix = "${local.name_prefix}-cache"
  description = "${data.aws_default_tags.current.tags.application} ${data.aws_default_tags.current.tags.environment-name} ${data.aws_region.current.name} cache sg"
  vpc_id      = data.aws_vpc.main.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elasticache_subnet_group" "private_subnets" {
  provider   = aws.region
  name       = "${local.name_prefix}-application-subnets"
  subnet_ids = data.aws_subnet.application[*].id
}

resource "aws_elasticache_replication_group" "weblate_cache" {
  provider                   = aws.region
  automatic_failover_enabled = true
  replication_group_id       = "${local.name_prefix}-cache"
  description                = "weblate redis cache"
  parameter_group_name       = "default.redis7"
  engine_version             = "7.0"
  node_type                  = "cache.t3.micro"
  engine                     = "redis"
  num_cache_clusters         = 2
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  subnet_group_name          = aws_elasticache_subnet_group.private_subnets.name
  security_group_ids         = [aws_security_group.weblate_cache.id]
}
