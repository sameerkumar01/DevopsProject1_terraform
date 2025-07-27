# IAM Role for CodeDeploy (no changes needed here)
resource "aws_iam_role" "codedeploy_role" {
  name               = "${local.name_prefix}-codedeploy-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "codedeploy.amazonaws.com" }
    }]
  })
  tags = local.common_tags
}
resource "aws_iam_role_policy_attachment" "codedeploy_policy_attachment" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# CodeDeploy Application (no changes needed here)
resource "aws_codedeploy_app" "main" {
  compute_platform = "Server"
  name             = "${local.name_prefix}-app"
  tags             = local.common_tags
}

# ---------------------------------------------------------------------------
# UPDATED CODEDEPLOY DEPLOYMENT GROUP
# ---------------------------------------------------------------------------
resource "aws_codedeploy_deployment_group" "main" {
  app_name              = aws_codedeploy_app.main.name
  deployment_group_name = "${local.name_prefix}-dg"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  # Instead of filtering by EC2 tags, we now point directly to the ASG.
  autoscaling_groups = [aws_autoscaling_group.main.name]

  # This tells CodeDeploy how to use the load balancer for zero-downtime deployments.
  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.main.name
    }
  }

  # We can now use WITH_TRAFFIC_CONTROL because we have a load balancer.
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }
}
