resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "${data.aws_default_tags.current.tags.application}-${data.aws_default_tags.current.tags.environment-name}-application-logs"
  retention_in_days = var.application_log_retention_days
  provider          = aws.region
}
resource "aws_cloudwatch_query_definition" "app_container_messages" {
  name            = "Weblate Application Logs/${data.aws_default_tags.current.tags.environment-name} weblate container messages"
  log_group_names = [aws_cloudwatch_log_group.application_logs.name]

  query_string = <<EOF
fields @timestamp, message, concat(method, " ", url) as request, status
| filter @message not like "ELB-HealthChecker"
| sort @timestamp desc
EOF
  provider     = aws.region
}
