# Data source to find the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# IAM Role and Instance Profile for the EC2 instances (no changes needed here)
resource "aws_iam_role" "ec2_role" {
  name               = "${local.name_prefix}-ec2-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
  tags = local.common_tags
}
resource "aws_iam_role_policy_attachment" "ec2_codedeploy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${local.name_prefix}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# Security Group for the EC2 instances (no changes needed here)
resource "aws_security_group" "ec2_sg" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "Allow HTTP and SSH inbound traffic"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# LAUNCH TEMPLATE
# This is a blueprint that defines how to configure each new EC2 instance.
# ---------------------------------------------------------------------------
resource "aws_launch_template" "main" {
  name_prefix   = "${local.name_prefix}-lt-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_instance_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y ruby wget httpd
              cd /home/ec2-user
              wget https://aws-codedeploy-${var.aws_region}.s3.${var.aws_region}.amazonaws.com/latest/install
              chmod +x ./install
              ./install auto
              service codedeploy-agent start
              service httpd start
              chkconfig httpd on
              EOF
  )

  # FIX: Add tag_specifications to apply tags, including the Name tag,
  # to every instance launched from this template.
  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-web-server"
    })
  }
}

# ---------------------------------------------------------------------------
# AUTO SCALING GROUP (ASG)
# This resource replaces the single aws_instance. It manages a group of
# identical instances to ensure high availability and scalability.
# ---------------------------------------------------------------------------
resource "aws_autoscaling_group" "main" {
  name                = "${local.name_prefix}-asg"
  desired_capacity    = 2 # Start with 2 instances for high availability
  max_size            = 5 # Scale up to 5 instances under heavy load
  min_size            = 2 # Always keep at least 2 instances running

  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.main.arn]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
}
