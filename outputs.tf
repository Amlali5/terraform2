output "load_balancer_dns" {
  value = aws_lb.my_alb.dns_name
  description = "Access the application using this Load Balancer DNS"
}
output "autoscaling_group_name" {
  value = aws_autoscaling_group.my_asg.name
  description = "The name of the Auto Scaling Group"
}