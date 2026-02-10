variable "lambda_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "twilio-webchat-server"
}

variable "aws_region" {
  description = "aws region"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name (staging, production, etc.)"
  type        = string
}

variable "additional_environment_variables" {
  description = "Additional environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "network" {
  type = object({
    vpc_env    = string
    alb_number = optional(number, 0)
  })
}

variable "profile" {
  type        = string
  description = "AWS account profile"
}
