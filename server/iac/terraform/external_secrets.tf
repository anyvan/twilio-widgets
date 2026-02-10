# Single app secret (JSON) for Twilio + SendGrid credentials.
# Update the secret value in AWS Secrets Manager with your Twilio and SendGrid keys.
resource "aws_secretsmanager_secret" "app_secrets" {
  name        = "${local.secret_prefix}-twilio-webchat-app-secret"
  description = "Twilio and SendGrid credentials for twilio-webchat-server (JSON)"

  tags = merge(local.tags, {
    Name = "${local.secret_prefix}-twilio-webchat-app-secret"
  })
}

# Placeholder version so the secret exists; replace via Console/CLI with real values.
resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    twilio = {
      ACCOUNT_SID               = ""
      API_KEY                   = ""
      API_SECRET                = ""
      AUTH_TOKEN                = ""
      ADDRESS_SID               = ""
      CONVERSATIONS_SERVICE_SID = ""
      TWILIO_REGION             = "stage-us1"
    }
    sendgrid = {
      SENDGRID_API_KEY = ""
      FROM_EMAIL       = ""
    }
  })
}
