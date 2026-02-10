output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.twilio_webchat_lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.twilio_webchat_lambda.arn
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.twilio_webchat_api.id
}
