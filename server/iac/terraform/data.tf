data "terraform_remote_state" "network" {
  backend   = "s3"
  workspace = "live-${var.network.vpc_env}_vpc"

  config = {
    bucket         = "anyvan-terraform-state-file-aws-accounts"
    key            = "iac-terraform-network.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "anyvan-terraform-state-file-lock-aws-accounts"
  }
}

data "terraform_remote_state" "lambda_layers" {
  backend   = "s3"
  workspace = "prod-shared-lambda-layers"
  config = {
    bucket         = "anyvan-terraform-state-file-aws-accounts"
    key            = "anyvan-lambda-layers.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "anyvan-terraform-state-file-lock-aws-accounts"
  }
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}
