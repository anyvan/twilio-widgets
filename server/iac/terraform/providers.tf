terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "anyvan-terraform-state-file-aws-accounts"
    key            = "twilio-webchat-server-lambda-project.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "anyvan-terraform-state-file-lock-aws-accounts"
  }
}

provider "aws" {
  region  = "eu-west-1"
  profile = var.profile

  default_tags {
    tags = local.tags
  }
}
