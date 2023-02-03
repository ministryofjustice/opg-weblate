data "aws_elasticache_replication_group" "weblate_cache" {
  provider = aws.region
  replication_group_id = "weblate-cache"
}
