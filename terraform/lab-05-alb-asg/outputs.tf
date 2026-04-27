output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "ALB DNS name"
}

output "alb_url" {
  value       = "http://${aws_lb.main.dns_name}"
  description = "Open this URL in a browser, refresh to see load balancing"
}

output "asg_name" {
  value       = aws_autoscaling_group.asg.name
  description = "Auto Scaling Group name"
}

output "target_group_arn" {
  value       = aws_lb_target_group.tg.arn
  description = "Target group ARN"
}
