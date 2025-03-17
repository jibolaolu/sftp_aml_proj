# # Create IAM Role for ECS Task Execution
# resource "aws_iam_role" "ecs_task_execution_role" {
#   name = "ecs-task-execution-role"
#
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement: [
#       {
#         Effect    = "Allow",
#         Principal = { Service = "ecs-tasks.amazonaws.com" },
#         Action    = "sts:AssumeRole"
#       }
#     ]
#   })
# }
#
# # Attach Policies to Task Execution Role
# resource "aws_iam_role_policy_attachment" "ecs_task_execution_logs_policy_attachment" {
#   role       = aws_iam_role.ecs_task_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }
#
# # Add Execute Command Permissions to Task Execution Role
# resource "aws_iam_policy" "ecs_execute_command_policy" {
#   name   = "ecs-execute-command-policy"
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement: [
#       {
#         Effect   = "Allow",
#         Action   = [
#           "ssmmessages:CreateControlChannel",
#           "ssmmessages:CreateDataChannel",
#           "ssmmessages:OpenControlChannel",
#           "ssmmessages:OpenDataChannel",
#           "ecs:ExecuteCommand"
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }
#
# resource "aws_iam_role_policy_attachment" "ecs_task_execution_execute_command_policy_attachment" {
#   role       = aws_iam_role.ecs_task_execution_role.name
#   policy_arn = aws_iam_policy.ecs_execute_command_policy.arn
# }
#
# # Create IAM Role for ECS Task
# resource "aws_iam_role" "ecs_task_role" {
#   name = "ecs-task-role"
#
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement: [
#       {
#         Effect    = "Allow",
#         Principal = { Service = "ecs-tasks.amazonaws.com" },
#         Action    = "sts:AssumeRole"
#       }
#     ]
#   })
# }
#
# # IAM Policy for S3 Access
# resource "aws_iam_policy" "ecs_s3_access_policy" {
#   name   = "ecs-s3-access-policy"
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement: [
#       {
#         Effect   = "Allow",
#         Action   = [
#           "s3:PutObject",
#           "s3:GetObject",
#           "s3:ListBucket"
#         ],
#         Resource = [
#           aws_s3_bucket.transfer_bucket.arn,
#           "${aws_s3_bucket.transfer_bucket.arn}/*"
#         ]
#       }
#     ]
#   })
# }
#
# # Attach S3 Access Policy to Task Role
# resource "aws_iam_role_policy_attachment" "ecs_s3_access_policy_attachment" {
#   role       = aws_iam_role.ecs_task_role.name
#   policy_arn = aws_iam_policy.ecs_s3_access_policy.arn
# }
#
# # Add Execute Command Permissions to Task Role
# resource "aws_iam_role_policy_attachment" "ecs_task_role_execute_command_policy_attachment" {
#   role       = aws_iam_role.ecs_task_role.name
#   policy_arn = aws_iam_policy.ecs_execute_command_policy.arn
# }
#
#
# # Create ECS Cluster
# resource "aws_ecs_cluster" "ecs_cluster" {
#   name = var.ecs_cluster_name
# }
#
# # Create ECS Task Definition
# resource "aws_ecs_task_definition" "ecs_task" {
#   family                   = var.ecs_service_name
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#   task_role_arn            = aws_iam_role.ecs_task_role.arn
#   cpu                      = "256"
#   memory                   = "512"
#
#   container_definitions = jsonencode([
#     {
#       name      = var.ecs_service_name
#       image     = var.container_image
#       essential = true
#       portMappings = [
#         {
#           containerPort = 80
#           hostPort      = 80
#           protocol      = "tcp"
#         }
#       ]
#       environment = [
#         {
#           name  = "S3_BUCKET_NAME"
#           value = aws_s3_bucket.transfer_bucket.bucket
#         }
#       ]
#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name
#           awslogs-region        = var.region
#           awslogs-stream-prefix = "ecs"
#         }
#       }
#     }
#   ])
#
#   # Enable Execute Command
#   runtime_platform {
#     operating_system_family = "LINUX"
#     cpu_architecture        = "X86_64"
#   }
# }
#
#
# # Create ECS Service
# resource "aws_ecs_service" "ecs_service" {
#   name            = var.ecs_service_name
#   cluster         = aws_ecs_cluster.ecs_cluster.id
#   task_definition = aws_ecs_task_definition.ecs_task.arn
#   desired_count   = 1
#   launch_type     = "FARGATE"
#
#   network_configuration {
#     subnets         = var.subnet_ids
#     security_groups = [aws_security_group.ecs_service_sg.id]
#     assign_public_ip = true
#   }
#
#   enable_execute_command = true
#
#   tags = {
#     Environment = var.environment
#     Service     = var.service
#   }
# }
#
#
# # Create Security Group for ECS Service
# resource "aws_security_group" "ecs_service_sg" {
#   name        = "ecs-service-sg"
#   description = "Allow traffic to ECS service"
#   vpc_id      = var.vpc_id
#
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }
#
# resource "aws_cloudwatch_log_group" "ecs_log_group" {
#   name              = "/ecs/${local.resource_prefix}-sftp"
#   retention_in_days = 7
#
#   tags = {
#     Environment = var.environment
#     Service     = var.service
#   }
# }
#
# # resource "aws_iam_role_policy_attachment" "ecs_execute_command_ssm" {
# #   role       = aws_iam_role.ecs_task_execution_role.name
# #   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
# # }
# #
# # resource "aws_iam_role_policy_attachment" "ecs_execute_command_ecs" {
# #   role       = aws_iam_role.ecs_task_execution_role.name
# #   policy_arn = "arn:aws:iam::aws:policy/AmazonECSExecuteCommandRolePolicy"
# # }
# #
# # resource "aws_vpc_endpoint" "ssm" {
# #   service_name = "com.amazonaws.${var.region}.ssm"
# #   vpc_id       = var.vpc_id
# # }
# #
# # resource "aws_vpc_endpoint" "ssmmessages" {
# #   service_name = "com.amazonaws.${var.region}.ssmmessages"
# #   vpc_id       = var.vpc_id
# # }
# #
# # resource "aws_vpc_endpoint" "ec2messages" {
# #   service_name = "com.amazonaws.${var.region}.ec2messages"
# #   vpc_id       = var.vpc_id
# # }
#
#
#
#
#
#
