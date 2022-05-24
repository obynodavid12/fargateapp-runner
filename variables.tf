variable "ACCESS_TOKEN" {
  description = "AWS SecretsManager ARN for personal access token"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "aws region"
  type        = string
  default     = "us-east-2"
}

# variable "aws_secret_access_key" {
#   description = "aws secret access"
#   type        = string
#   default     = ""
# }

# variable "aws_access_key_id" {
#   description = "aws access key"
#   type        = string
#   default     = ""
# }

variable "RUNNER_NAME" {
  description = "the name of the runner"
  type        = string
  default     = "fargate-runner1"
}
variable "RUNNER_LABELS" {
  description = "the name of the self hosted runner"
  type        = string
  default     = "fargate-runner1"
}

variable "RUNNER_REPOSITORY_URL" {
  description = "the url of the repository"
  type        = string
  default     = "https://github.com/obynodavid12/fargateapp-runner"
}

variable "prefix" {
  default = "ecs-runner"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  default     = "172.31.0.0/16"
}

variable "private_subnet_cidr" {
  description = "CIDR for the Private Subnet"
  default     = "172.31.32.0/20"
}

variable "public_subnet_cidr" {
  description = "CIDR for the Public Subnet"
  default     = "172.31.48.0/20"
}

# variable "fargate_cpu" {
#   description = "Fargate instance CPU units to provision"
#   type        = number
#   default     = "256"
# }

# variable "fargate_memory" {
#   description = "Fargate instance memory units to provision"
#   type        = number
#   default     = "512"
# }

# variable "ecr_repo_url" {
#   description = "Docker image to be run in the ECS cluster"
#   default     = "106878672844.dkr.ecr.us-east-2.amazonaws.com/ecs-runner:latest"
# }

