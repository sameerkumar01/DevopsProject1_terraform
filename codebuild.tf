# This file defines the CodeBuild project. Since you have a simple
# HTML/CSS/JS project, the buildspec is very simple. It just passes
# all the files along to the next stage.

resource "aws_codebuild_project" "main" {
  name          = "${local.name_prefix}-build"
  description   = "CodeBuild project for ${local.name_prefix}"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = "30"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2
      phases:
        build:
          commands:
            - echo "No build step required for static HTML site. Passing files through."
      artifacts:
        files:
          - '**/*'
    EOT
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
  }

  tags = local.common_tags
}
