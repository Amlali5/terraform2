# Launch Template
resource "aws_launch_template" "my_launch_template" {
  name_prefix   = "my-launch-template"
  image_id      = "ami-0c02fb55956c7d316" # Replace with your desired AMI ID
  instance_type = "t2.micro"
 

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from $(hostname -I)" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "my-asg-instance"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "my_asg" {
  name_prefix               = "my-asg-"
  desired_capacity          = 2
  max_size                  = 2
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  vpc_zone_identifier       = [aws_subnet.private_subnet_az1.id, aws_subnet.private_subnet_az2.id]
  target_group_arns         = [aws_lb_target_group.my_target_group.arn]

  launch_template {
    id      = aws_launch_template.my_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "my-asg-instance"
    propagate_at_launch = true
  }
}

# Scaling Policy (CPU-based)
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.my_asg.id
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.my_asg.id
}

# CloudWatch Alarms for Scaling
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name                = "high-cpu"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 70
  alarm_actions             = [aws_autoscaling_policy.scale_up.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.my_asg.id
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name                = "low-cpu"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 30
  alarm_actions             = [aws_autoscaling_policy.scale_down.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.my_asg.id
  }
}