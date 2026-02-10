module "security_group" {
  source  = "terraform-registry.anyvan.com/anyvan/security_group/aws"
  version = "~> 2.0"

  name_prefix = "${local.name}-lambda"
  description = "Security group for twilio-webchat-server Lambda function"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc.vpc_id

  egress = {
    "allow_all_tcp" = {
      port        = "0"
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
