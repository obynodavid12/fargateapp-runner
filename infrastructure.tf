terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.63"
    }
    random = {
      source  = "hashicorp/aws"
      version = ">=3.0.0"
    }
  }

  cloud {
    organization = "Dataalgebra-Cloud"

    workspaces {
      name = "AWS-DataalgebraCloud"
    }
  }
}


# VPC
resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

# Internet Gateway for the Public Subnets
resource "aws_internet_gateway" "int_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.prefix}_int_gateway"
  }
}

# Private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "us-east-2c"

  tags = {
    Name = "${var.prefix}_private_subnet"
  }
}

# Public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = "us-east-2c"

  tags = {
    Name = "${var.prefix}_public_subnet"
  }
}

# Nat Gateway for private subnet
resource "aws_eip" "nat_gateway_eip" {
  vpc = true
  tags = {
    Name = "${var.prefix}_nat_gateway_eip"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "${var.prefix}_nat_gateway"
  }
}

# Public route table
resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.int_gateway.id
  }

  tags = {
    Name = "${var.prefix}_public"
  }
}

# Private route table
resource "aws_route_table" "route_table_private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "${var.prefix}_private"
  }
}

# Associations
resource "aws_route_table_association" "assoc_1" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.route_table_public.id
}

resource "aws_route_table_association" "assoc_2" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.route_table_private.id
}

# ECR repository
resource "aws_ecr_repository" "ECR_repository" {
  name                 = var.prefix
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ECS cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.prefix}-cluster"
  capacity_providers = [
  "FARGATE"]
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Task execution role for used for ECS
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.prefix}_ecs_task_execution_role"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

# Attach policy to task execution role
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "admin-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Secrets
resource "aws_secretsmanager_secret" "ACCESS_TOKEN" {
  name = "${var.prefix}-ACCESS_TOKEN"
}

resource "aws_secretsmanager_secret_version" "ACCESS_TOKEN_version" {
  secret_id     = aws_secretsmanager_secret.ACCESS_TOKEN.id
  secret_string = var.ACCESS_TOKEN
}


# Task definition
resource "aws_cloudwatch_log_group" "ecs-log-group" {
  name = "/ecs/${var.prefix}-task-def"
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = "${var.prefix}-task-def"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = "1024"
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = <<TASK_DEFINITION
  [
    {
      "name": "ecs-runner",
      "image": "106878672844.dkr.ecr.us-east-2.amazonaws.com/ecs-runner:latest",
      "cpu": 256,
      "memory": 512,
      "essential": true,
      "network_mode": "awsvpc",
      "portMappings": [],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-region": "us-east-2",
            "awslogs-group": "/ecs/${var.prefix}-task-def",
            "awslogs-stream-prefix": "ecs" 
        
        }
      },
      "entryPoint": ["/entrypoint.sh"],
      "command": ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"],
      "secrets": [
        {"name": "ACCESS_TOKEN", "valueFrom": "${aws_secretsmanager_secret.ACCESS_TOKEN.arn}"}
      ],
      "environment": [
        {"name": "RUNNER_NAME", "value": "${var.RUNNER_NAME}"},
        {"name": "RUNNER_REPOSITORY_URL", "value": "${var.RUNNER_REPOSITORY_URL}"},
        {"name": "RUNNER_LABELS", "value": "${var.RUNNER_LABELS}"}
      ]
       
    }
  ]
  TASK_DEFINITION
}

# A security group for ECS
resource "aws_security_group" "ecs_sg" {
  name        = "${var.prefix}-ecs-sg"
  description = "Allow incoming traffic for ecs"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}_ecs_sg"
  }
}

resource "aws_ecs_service" "ecs_service" {
  name            = "${var.prefix}-ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = "1"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = [aws_subnet.private_subnet.id]
    assign_public_ip = false
  }
}


# Giving a Fargate access to the Secrets in the Secret Manager
resource "aws_iam_role_policy" "password_policy_secretsmanager" {
  name = "password-policy-secretsmanager"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "secretsmanager:GetSecretValue"
        ],
        "Effect": "Allow",
        "Resource": [
            "${aws_secretsmanager_secret.ACCESS_TOKEN.arn}"
        ]
      }
    ]
  }
  EOF
}