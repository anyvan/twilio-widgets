# Twilio Webchat Server - Terraform Infrastructure

This directory contains the Terraform configuration for deploying the Twilio Webchat server as an AWS Lambda function with API Gateway.

## Architecture

- **Lambda Function**: Runs the Express server using `@vendia/serverless-express`
- **API Gateway**: Provides HTTP endpoints that proxy to the Lambda function
- **Secrets Manager**: Single app secret (JSON) storing Twilio and SendGrid credentials
- **VPC**: Lambda runs within a VPC for security
- **CloudWatch**: Logging and monitoring

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform 1.8.5 or later
3. Access to the AnyVan AWS accounts (test1 for staging, production for production)

## Secrets Required

Terraform creates a single app secret: **`{env}-twilio-webchat-app-secret`** (e.g. `stage-twilio-webchat-app-secret`, `prod-twilio-webchat-app-secret`). Update this secret in AWS Secrets Manager with your Twilio and SendGrid credentials using the following JSON shape:

### App secret (`{env}-twilio-webchat-app-secret`)
```json
{
  "twilio": {
    "ACCOUNT_SID": "ACxxxxx",
    "API_KEY": "SKxxxxx",
    "API_SECRET": "xxxxx",
    "AUTH_TOKEN": "xxxxx",
    "ADDRESS_SID": "IGxxxxx",
    "CONVERSATIONS_SERVICE_SID": "ISxxxxx",
    "TWILIO_REGION": "stage-us1"
  },
  "sendgrid": {
    "SENDGRID_API_KEY": "SGxxxxx",
    "FROM_EMAIL": "noreply@example.com"
  }
}
```

After `terraform apply`, open the secret in the AWS Console (or use the CLI) and replace the placeholder values with your real Twilio and SendGrid credentials.

## Deployment

### Staging

```bash
cd server/iac/terraform
terraform init
terraform workspace select stage || terraform workspace new stage
terraform plan -var-file=env/staging.tfvars.json
terraform apply -var-file=env/staging.tfvars.json
```

### Production

```bash
cd server/iac/terraform
terraform init
terraform workspace select production || terraform workspace new production
terraform plan -var-file=env/production.tfvars.json
terraform apply -var-file=env/production.tfvars.json
```

## Outputs

After deployment, Terraform will output:

- `api_gateway_url`: The base URL for the API Gateway endpoint
- `lambda_function_name`: The name of the deployed Lambda function
- `lambda_function_arn`: The ARN of the Lambda function

## Endpoints

The API Gateway exposes the following endpoints:

- `POST /initWebchat` - Initialize a new webchat session
- `POST /refreshToken` - Refresh an expired token
- `POST /email` - Send transcript email
- `GET /health` - Health check endpoint

## Local Development

For local development, the server will use environment variables from `.env` instead of AWS Secrets Manager. See the root `.env.sample` file for required variables.

## CI/CD

The CircleCI pipeline automatically deploys the infrastructure:

- **Non-main branches**: Deploy to staging
- **Main branch**: Deploy to production

The pipeline includes:
1. Build the server code
2. Run Terraform plan
3. Apply Terraform changes
4. Deploy the Lambda function

## Troubleshooting

### Lambda Logs

```bash
aws logs tail /aws/lambda/twilio-webchat-server-{environment} --follow --profile {profile}
```

### API Gateway Logs

```bash
aws logs tail /aws/apigateway/twilio-webchat-server-{environment} --follow --profile {profile}
```

### Testing the API

```bash
# Health check
curl https://{api-gateway-id}.execute-api.eu-west-1.amazonaws.com/{environment}/health

# Initialize webchat
curl -X POST https://{api-gateway-id}.execute-api.eu-west-1.amazonaws.com/{environment}/initWebchat \
  -H "Content-Type: application/json" \
  -d '{"formData":{"friendlyName":"Test User"}}'
```
