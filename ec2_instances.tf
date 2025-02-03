resource "aws_instance" "ec2_private_az1" {
  ami           = "ami-0c02fb55956c7d316"  
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet_az1.id
  security_groups = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from $(hostname -I)" > /var/www/html/index.html
              EOF

  tags = {
    Name = "ec2-private-az1"
  }
}

resource "aws_instance" "ec2_private_az2" {
  ami           = "ami-0c02fb55956c7d316"  
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet_az2.id
  security_groups = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from $(hostname -I)" > /var/www/html/index.html
              EOF

  tags = {
    Name = "ec2-private-az2"
  }
}

resource "aws_lb_target_group_attachment" "ec2_az1_attachment" {
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id        = aws_instance.ec2_private_az1.id
  port            = 80
}

resource "aws_lb_target_group_attachment" "ec2_az2_attachment" {
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id        = aws_instance.ec2_private_az2.id
  port            = 80
}