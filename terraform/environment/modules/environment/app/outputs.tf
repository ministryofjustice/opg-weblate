output "load_balancer" {
  value = aws_lb.weblate
}

output "load_balancer_security_group" {
  value = aws_security_group.weblate_loadbalancer
}
