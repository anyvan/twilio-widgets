# Twilio Webchat Widget - Deployment Guide

This document describes the complete deployment setup for the Twilio Webchat Widget project, matching the deployment architecture of the callback-widget project.

## Overview

The project now supports automated deployment to AWS with:

1. **Widget Deployment**: React app built and deployed to S3
2. **Server Deployment**: Express server deployed as AWS Lambda with API Gateway
3. **Infrastructure as Code**: Terraform manages all AWS resources
4. **CI/CD**: CircleCI handles automated builds and deployments

## Architecture

### Widget (Frontend)
- **Build**: React app compiled to single JavaScript file
- **Deployment**: Uploaded to S3 with hash-based filename for cache-busting
- **CDN**: Served via CloudFront
- **URLs**:
  - Staging: `https://staging-assets.anyvan.com/widgets/twilio-webchat-widget.{hash}.js`
  - Production: `https://assets.anyvan.com/widgets/twilio-webchat-widget.{hash}.js`

### Server (Backend)
- **Runtime**: AWS Lambda (Node.js 22.x)
- **API**: API Gateway REST API
- **Secrets**: AWS Secrets Manager
- **VPC**: Deployed in AnyVan VPC for security
- **URLs**:
  - Staging: `https://{api-id}.execute-api.eu-west-1.amazonaws.com/staging`
  - Production: `https://{api-id}.execute-api.eu-west-1.amazonaws.com/production`

## New Files Created

### 1. CodeArtifact Authentication
- `codeartifact.sh` - Script to authenticate with AWS CodeArtifact for private npm packages

### 2. Server Lambda Handler
- `server/lambda.js` - Lambda handler wrapper for Express app using `@vendia/serverless-express`

### 3. Secrets Management
- `server/helpers/getSecrets.js` - Helper to fetch secrets from AWS Secrets Manager or environment variables

### 4. Terraform Infrastructure
All files in `server/iac/terraform/`:
- `main.tf` - Lambda function and IAM roles
- `api_gateway.tf` - API Gateway configuration
- `providers.tf` - Terraform and AWS provider setup
- `variables.tf` - Input variables
- `locals.tf` - Local values and tags
- `data.tf` - Data sources (network, lambda layers)
- `iam_policy.tf` - IAM policies for Lambda
- `external_secrets.tf` - References to existing secrets
- `security_group.tf` - VPC security group
- `outputs.tf` - Output values
- `env/staging.tfvars.json` - Staging environment variables
- `env/production.tfvars.json` - Production environment variables
- `README.md` - Infrastructure documentation

### 5. Documentation
- `DEPLOYMENT.md` - This file
- Updated `README.md` - Added AWS deployment section

## Modified Files

### 1. CircleCI Configuration (`.circleci/config.yml`)
**Added:**
- `terraform-helper` orb for Terraform deployments
- `terraform_version` parameter
- `login-codeartifact-registry` job
- `build_widget` job - Builds React widget
- `build_server` job - Prepares server for Lambda deployment
- `deploy_staging` and `deploy_production` jobs - Deploy widget to S3
- Terraform deployment jobs in both workflows

**Workflows Updated:**
- `deploy_on_branch`: Deploys to staging on feature branches
- `deploy_main`: Deploys to production on main branch

### 2. Package Dependencies (`package.json`)
**Added:**
- `@vendia/serverless-express` - Lambda wrapper for Express
- `aws-sdk` - AWS SDK for Secrets Manager

### 3. Server Code Updates
**Modified to support AWS Secrets Manager:**
- `server/helpers/getTwilioClient.js` - Now async, uses getSecrets
- `server/helpers/createToken.js` - Now async, uses getSecrets
- `server/helpers/email.js` - Now async, uses getSecrets
- `server/controllers/initWebchatController.js` - Updated for async secrets
- `server/controllers/refreshTokenController.js` - Updated for async secrets

### 4. Git Configuration (`.gitignore`)
**Added:**
- Terraform state files
- Terraform lock file
- Lambda zip file

## AWS Resources Created by Terraform

### Lambda Function
- **Name**: `twilio-webchat-server-{environment}`
- **Runtime**: Node.js 22.x
- **Memory**: 1024 MB
- **Timeout**: 30 seconds
- **Concurrency**: 10

### API Gateway
- **Type**: REST API
- **Stage**: Environment name (staging/production)
- **Endpoints**:
  - `POST /initWebchat`
  - `POST /refreshToken`
  - `POST /email`
  - `GET /health`

### IAM Roles & Policies
- Lambda execution role
- API Gateway logging role
- Secrets Manager read permissions
- VPC access permissions
- CloudWatch logging permissions

### CloudWatch Log Groups
- `/aws/lambda/twilio-webchat-server-{environment}` (14 day retention)
- `/aws/apigateway/twilio-webchat-server-{environment}` (14 day retention)

### Security
- VPC security group for Lambda
- Secrets Manager integration
- API Gateway access logging

## Secrets Configuration

### Twilio Secrets
**Secret Name**: `{environment}-twilio-flex-secret`

```json
{
  "ACCOUNT_SID": "ACxxxxx",
  "API_KEY": "SKxxxxx",
  "API_SECRET": "xxxxx",
  "AUTH_TOKEN": "xxxxx",
  "ADDRESS_SID": "IGxxxxx",
  "CONVERSATIONS_SERVICE_SID": "ISxxxxx",
  "TWILIO_REGION": "stage-us1"
}
```

### SendGrid Secrets
**Secret Name**: `{environment}-sendgrid-secret`

```json
{
  "SENDGRID_API_KEY": "SGxxxxx",
  "FROM_EMAIL": "noreply@example.com"
}
```

## Deployment Process

### Automated (CircleCI)

#### Feature Branches
1. Compliance check
2. AWS authentication
3. CodeArtifact login
4. Run tests (unit tests, Cypress)
5. Build widget
6. Build server
7. Deploy server to staging (Terraform)
8. Deploy widget to staging S3

#### Main Branch
1. Compliance check
2. AWS authentication
3. CodeArtifact login
4. Run tests (unit tests, Cypress)
5. Build widget
6. Build server
7. Deploy server to production (Terraform)
8. Deploy widget to production S3

### Manual

#### Widget Deployment
```bash
# Build
yarn install
yarn build

# Deploy to staging
aws s3 cp build/static/js/main.js \
  s3://staging-assets-anyvan/widgets/twilio-webchat-widget.$(sha256sum build/static/js/main.js | cut -d' ' -f1 | head -c 8).js \
  --profile test1 \
  --content-type "application/javascript" \
  --cache-control "public, max-age=31536000"

# Deploy to production
aws s3 cp build/static/js/main.js \
  s3://prod-assets-anyvan/widgets/twilio-webchat-widget.$(sha256sum build/static/js/main.js | cut -d' ' -f1 | head -c 8).js \
  --profile production \
  --content-type "application/javascript" \
  --cache-control "public, max-age=31536000"
```

#### Server Deployment
```bash
cd server/iac/terraform

# Staging
terraform init
terraform workspace select stage || terraform workspace new stage
terraform plan -var-file=env/staging.tfvars.json
terraform apply -var-file=env/staging.tfvars.json

# Production
terraform workspace select production || terraform workspace new production
terraform plan -var-file=env/production.tfvars.json
terraform apply -var-file=env/production.tfvars.json
```

## Testing Deployed Services

### Health Check
```bash
curl https://{api-id}.execute-api.eu-west-1.amazonaws.com/{environment}/health
```

### Initialize Webchat
```bash
curl -X POST https://{api-id}.execute-api.eu-west-1.amazonaws.com/{environment}/initWebchat \
  -H "Content-Type: application/json" \
  -d '{"formData":{"friendlyName":"Test User"}}'
```

### View Lambda Logs
```bash
# Staging
aws logs tail /aws/lambda/twilio-webchat-server-staging --follow --profile test1

# Production
aws logs tail /aws/lambda/twilio-webchat-server-production --follow --profile production
```

## Monitoring

### CloudWatch Metrics
- Lambda invocations
- Lambda errors
- Lambda duration
- API Gateway requests
- API Gateway 4xx/5xx errors

### CloudWatch Logs
- Lambda execution logs
- API Gateway access logs

### Alarms (Optional - Not Currently Configured)
Consider adding CloudWatch Alarms for:
- Lambda error rate > 5%
- API Gateway 5xx rate > 1%
- Lambda throttles > 0

## Rollback Procedures

### Widget Rollback
Since widgets are deployed with hash-based filenames, rollback is simply updating the HTML to reference the previous hash.

### Server Rollback
```bash
cd server/iac/terraform
terraform workspace select {environment}

# Revert to previous state
terraform state pull > current-state.json
# Restore previous state file from S3
terraform apply -var-file=env/{environment}.tfvars.json
```

Or use CircleCI to redeploy a previous commit.

## Cost Considerations

### Lambda
- **Pricing**: $0.20 per 1M requests + $0.0000166667 per GB-second
- **Free Tier**: 1M requests + 400,000 GB-seconds per month

### API Gateway
- **Pricing**: $3.50 per million requests (first 333M)
- **Free Tier**: 1M requests per month for 12 months

### Secrets Manager
- **Pricing**: $0.40 per secret per month + $0.05 per 10,000 API calls
- **Estimate**: ~$0.80/month for 2 secrets

### S3
- **Pricing**: $0.023 per GB per month
- **Estimate**: < $1/month for widget files

### Total Estimated Cost
- **Development/Staging**: < $5/month
- **Production**: Depends on traffic, likely < $50/month for moderate traffic

## Security Considerations

1. **Secrets Management**: All credentials stored in AWS Secrets Manager
2. **VPC**: Lambda runs in VPC with security group
3. **IAM**: Principle of least privilege for all roles
4. **HTTPS**: All traffic encrypted in transit
5. **Origin Validation**: Server validates request origins
6. **CORS**: Properly configured CORS headers
7. **CloudWatch Logs**: All requests logged for audit

## Troubleshooting

### Lambda Cold Starts
- Typical cold start: 1-3 seconds
- If problematic, consider provisioned concurrency

### Secret Not Found
- Ensure secret exists in correct account
- Check secret name format: `{environment}-twilio-flex-secret`
- Verify Lambda has IAM permissions

### API Gateway 502 Errors
- Check Lambda logs for errors
- Verify Lambda response format is correct
- Check Lambda timeout (30s)

### CORS Errors
- Verify origin is in allowed list
- Check CORS middleware configuration
- Ensure preflight OPTIONS requests are handled

## Future Improvements

1. **CloudFront CDN**: Add CloudFront in front of S3 for better performance
2. **WAF**: Add AWS WAF for DDoS protection
3. **Monitoring**: Set up CloudWatch dashboards and alarms
4. **Auto-scaling**: Configure API Gateway throttling and Lambda reserved concurrency
5. **Blue/Green Deployments**: Implement Lambda aliases for safer deployments
6. **Integration Tests**: Add integration tests that run against deployed APIs

## Support

For issues or questions:
1. Check CloudWatch logs
2. Review Terraform state
3. Check CircleCI build logs
4. Refer to callback-widget project for reference implementation
