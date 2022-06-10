variable "PAT_TOKEN" {
  description = "AWS SecretsManager ARN for personal access token"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "aws region"
  type        = string
  default     = "us-east-2"
}

variable "secret_retention_days" {
  default     = 0
  description = "Number of days before secret is actually deleted. Increasing this above 0 will result in Terraform errors if you redeploy to the same workspace."
}
variable "RUNNER_NAME" {
  description = "the name of the runner"
  type        = string
  default     = "fargate-runner"
}
variable "RUNNER_LABELS" {
  description = "the name of the self hosted runner"
  type        = string
  default     = "fargate-runner"
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

variable "cloudwatch_retention_in_days" {
  type        = number
  description = "AWS CloudWatch Logs Retention in Days. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire."
  default     = 1
}


variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision"
  type        = number
  default     = "256"
}

variable "fargate_memory" {
  description = "Fargate instance memory units to provision"
  type        = number
  default     = "512"
}

variable "ecr_repo_url" {
  description = "Docker image to be run in the ECS cluster"
  default     = "106878672844.dkr.ecr.us-east-2.amazonaws.com/ecs-runner:latest"
}

variable "assign_public_ip" {
  description = "Choose whether to assign a public IP address to the Elastic Network Interface."
  type        = bool
  default     = false
}

variable "task_cpu" {
  description = "The ECS Task CPU size"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "The ECS Task memory size"
  type        = number
  default     = 1024
}
