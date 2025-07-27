
variable "project_name" {
  description = "A unique name for your project."
  type        = string
}

variable "environment" {
  description = "The environment for the deployment (e.g., 'dev', 'prod')."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "The AWS region where resources will be created."
  type        = string
}


variable "github_repo_owner" {
  description = "The owner of the GitHub repository (e.g., your GitHub username)."
  type        = string
}

variable "github_repo_name" {
  description = "The name of the GitHub repository."
  type        = string
}

variable "github_branch" {
  description = "The branch to be used by CodePipeline."
  type        = string
  default     = "main"
}
