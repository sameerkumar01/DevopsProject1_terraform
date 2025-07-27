# ---------------------------------------------------------------------------
# NETWORKING
# We will use the default VPC and its subnets for simplicity.
# ---------------------------------------------------------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ---------------------------------------------------------------------------
# APPLICATION LOAD BALANCER (ALB)
# This is the single entry point for all user traffic.
# ---------------------------------------------------------------------------
resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2_sg.id] # Reuse the same SG from ec2.tf
  subnets            = data.aws_subnets.default.ids

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# TARGET GROUP
# The ALB forwards traffic to this group, which contains our EC2 instances.
# ---------------------------------------------------------------------------
resource "aws_lb_target_group" "main" {
  name     = "${local.name_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path = "/" # The ALB will check this path to see if an instance is healthy.
  }

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# LISTENER
# This tells the ALB to listen for HTTP traffic on port 80 and forward
# it to our target group.
# ---------------------------------------------------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
