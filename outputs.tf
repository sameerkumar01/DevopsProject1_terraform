# This output provides the public DNS name of the Application Load Balancer.
# This is the URL you will use to access your website.
output "website_url" {
  description = "The public URL of the production website."
  value       = "http://${aws_lb.main.dns_name}"
}

# This output provides the ARN of the CodeStar Connection for GitHub.
output "codestar_connection_arn" {
  description = "The ARN of the CodeStar Connection for GitHub."
  value       = aws_codestarconnections_connection.github_connection.arn
}

# This output provides the name of the AWS CodePipeline.
output "codepipeline_name" {
  description = "The name of the AWS CodePipeline."
  value       = aws_codepipeline.main.name
}

# This output provides the name of the Auto Scaling Group for the test.
output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group."
  value       = aws_autoscaling_group.main.name
}
