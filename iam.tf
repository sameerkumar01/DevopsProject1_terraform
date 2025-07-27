# This file defines the IAM roles and policies needed by CodePipeline and CodeBuild.

# Data source to get the current AWS account ID for unique resource naming

data "aws_caller_identity" "current" {}

# Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "${local.name_prefix}-codepipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "codepipeline.amazonaws.com" }
    }]
  })
  tags = local.common_tags
}

# Policy for CodePipeline
resource "aws_iam_policy" "codepipeline_policy" {
  name        = "${local.name_prefix}-codepipeline-policy"
  description = "Policy for AWS CodePipeline."
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["s3:GetObject", "s3:GetObjectVersion", "s3:GetBucketVersioning", "s3:PutObject", "s3:ListBucket"],
        Effect   = "Allow",
        Resource = [aws_s3_bucket.codepipeline_artifacts.arn, "${aws_s3_bucket.codepipeline_artifacts.arn}/*"]
      },
      {
        Action   = ["codebuild:StartBuild", "codebuild:BatchGetBuilds"],
        Effect   = "Allow",
        Resource = aws_codebuild_project.main.arn
      },
      {
        Action   = ["codestar-connections:UseConnection"],
        Effect   = "Allow",
        Resource = aws_codestarconnections_connection.github_connection.arn
      },
      {
        Action   = ["codedeploy:CreateDeployment", "codedeploy:GetDeployment", "codedeploy:GetDeploymentConfig", "codedeploy:GetApplicationRevision", "codedeploy:RegisterApplicationRevision"],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

# Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "${local.name_prefix}-codebuild-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "codebuild.amazonaws.com" }
    }]
  })
  tags = local.common_tags
}

# Policy for CodeBuild
resource "aws_iam_policy" "codebuild_policy" {
  name        = "${local.name_prefix}-codebuild-policy"
  description = "Policy for AWS CodeBuild."
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject", "s3:ListBucket"],
        Effect   = "Allow",
        Resource = [aws_s3_bucket.codepipeline_artifacts.arn, "${aws_s3_bucket.codepipeline_artifacts.arn}/*"]
      },
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Effect   = "Allow",
        Resource = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${local.name_prefix}-build:*"]
      },
      {
        Action   = ["codestar-connections:UseConnection"],
        Effect   = "Allow",
        Resource = aws_codestarconnections_connection.github_connection.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}
