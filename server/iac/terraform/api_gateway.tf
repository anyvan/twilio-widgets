# API Gateway REST API
resource "aws_api_gateway_rest_api" "twilio_webchat_api" {
  name        = "${local.name}-api"
  description = "API Gateway for Twilio Webchat Server"

  tags = local.tags
}

# Catch-all proxy resource - forwards all requests to Lambda
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.twilio_webchat_api.id
  parent_id   = aws_api_gateway_rest_api.twilio_webchat_api.root_resource_id
  path_part   = "{proxy+}"
}

# Catch-all proxy method - handles ALL HTTP methods (GET, POST, OPTIONS, etc.)
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.twilio_webchat_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

# Root method to handle requests to the root path
resource "aws_api_gateway_method" "root" {
  rest_api_id   = aws_api_gateway_rest_api.twilio_webchat_api.id
  resource_id   = aws_api_gateway_rest_api.twilio_webchat_api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

# Lambda integration for proxy requests
resource "aws_api_gateway_integration" "proxy_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.twilio_webchat_api.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.twilio_webchat_lambda.invoke_arn
}

# Lambda integration for root requests
resource "aws_api_gateway_integration" "root_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.twilio_webchat_api.id
  resource_id             = aws_api_gateway_rest_api.twilio_webchat_api.root_resource_id
  http_method             = aws_api_gateway_method.root.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.twilio_webchat_lambda.invoke_arn
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "twilio_webchat_api" {
  depends_on = [
    aws_api_gateway_method.proxy,
    aws_api_gateway_method.root,
    aws_api_gateway_integration.proxy_lambda,
    aws_api_gateway_integration.root_lambda,
  ]

  rest_api_id = aws_api_gateway_rest_api.twilio_webchat_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy.id,
      aws_api_gateway_method.root.id,
      aws_api_gateway_integration.proxy_lambda.id,
      aws_api_gateway_integration.root_lambda.id,
      timestamp(), # Force redeployment
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.twilio_webchat_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.twilio_webchat_api.execution_arn}/*/*"
}

resource "aws_api_gateway_stage" "twilio_webchat_api" {
  depends_on = [aws_api_gateway_deployment.twilio_webchat_api]

  deployment_id = aws_api_gateway_deployment.twilio_webchat_api.id
  rest_api_id   = aws_api_gateway_rest_api.twilio_webchat_api.id
  stage_name    = var.environment

  # Optional stage-specific settings
  variables = {
    environment = var.environment
    version     = "v1"
  }

  # Access logging (optional but recommended)
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${local.name}"
  retention_in_days = 14

  tags = local.tags
}

# IAM role for API Gateway logging
resource "aws_iam_role" "api_gateway_logging" {
  name = "${local.name}-api-gateway-logging"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

# IAM policy for API Gateway logging
resource "aws_iam_role_policy" "api_gateway_logging" {
  name = "${local.name}-api-gateway-logging"
  role = aws_iam_role.api_gateway_logging.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# API Gateway account settings for logging
resource "aws_api_gateway_account" "twilio_webchat_api" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_logging.arn
}

output "api_gateway_url" {
  description = "Base URL for API Gateway"
  value       = "https://${aws_api_gateway_rest_api.twilio_webchat_api.id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}"
}
