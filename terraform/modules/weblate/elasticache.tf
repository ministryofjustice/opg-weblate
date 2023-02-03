data "aws_elasticache_replication_group" "weblate_cache" {
  provider = aws.region
  replication_group_id = "${data.aws_default_tags.current.tags.application}-${data.aws_default_tags.current.tags.environment-name}-${data.aws_region.current.name}-cache"
}
