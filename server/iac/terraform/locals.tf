locals {
  name = "${var.lambda_name}-${var.environment}"

  # Map full environment names to secret name prefixes
  env_to_secret_prefix = {
    staging    = "stage"
    production = "prod"
  }

  secret_prefix = local.env_to_secret_prefix[var.environment]

  tags = {
    Name              = local.name
    env               = var.environment
    squad             = "customer-comms"
    service           = "twilio-webchat-server"
    terraform_version = "1.8.5"
  }
}
