resource "aws_iam_role" "lambda_role" {
  name = "${local.name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "${local.name}-lambda-policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy" "lambda_cloudwatch_metrics" {
  name = "${local.name}-cloudwatch-metrics"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../../../server"
  output_path = "../lambda.zip"
  excludes = [
    "iac",
    "node_modules",
    ".env"
  ]
}

resource "aws_lambda_function" "twilio_webchat_lambda" {
  filename                       = data.archive_file.lambda_zip.output_path
  function_name                  = local.name
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "lambda.handler"
  runtime                        = "nodejs22.x"
  timeout                        = 30
  memory_size                    = 1024
  reserved_concurrent_executions = 10

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = merge(
      {
        APP_SECRET_NAME = aws_secretsmanager_secret.app_secrets.name
        ENVIRONMENT     = var.environment
        NODE_ENV        = var.environment
      },
      var.additional_environment_variables
    )
  }

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.name}"
  retention_in_days = 14
  tags              = local.tags
}
