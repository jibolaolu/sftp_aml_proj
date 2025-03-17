#
# # Variables for configurations
# variable "vpc_cidr" {
#   default = "10.0.0.0/16"
# }
# variable "subnet_cidr" {
#   default = "10.0.1.0/24"
# }
#
# # Create a VPC
# resource "aws_vpc" "main" {
#   cidr_block = var.vpc_cidr
#   tags = {
#     Name = "mongodb-vpc"
#   }
# }
#
# # Create a public subnet
# resource "aws_subnet" "public" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = var.subnet_cidr
#   map_public_ip_on_launch = true
#   availability_zone       = "eu-west-2a"
#   tags = {
#     Name = "mongodb-public-subnet"
#   }
# }
#
# # Internet Gateway
# resource "aws_internet_gateway" "main" {
#   vpc_id = aws_vpc.main.id
#   tags = {
#     Name = "mongodb-igw"
#   }
# }
#
# # Route Table for public subnet
# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.main.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.main.id
#   }
#   tags = {
#     Name = "public-route-table"
#   }
# }
#
# resource "aws_route_table_association" "public" {
#   subnet_id      = aws_subnet.public.id
#   route_table_id = aws_route_table.public.id
# }
#
# # Security Group for MongoDB
# resource "aws_security_group" "mongodb_sg" {
#   vpc_id = aws_vpc.main.id
#
#   ingress {
#     from_port   = 27017
#     to_port     = 27017
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # Open to the world (adjust for security)
#   }
#
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere (adjust for security)
#   }
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags = {
#     Name = "mongodb-sg"
#   }
# }
#
# # Launch EC2 instance for MongoDB in Docker
# resource "aws_instance" "mongodb" {
#   ami           = "ami-05bca204debf5aaeb" # Amazon Linux 2 AMI (Adjust for your region)
#   instance_type = "t2.micro"
#   subnet_id     = aws_subnet.public.id
#   security_groups = [aws_security_group.mongodb_sg.id]
#   key_name = "LinuxKeyPair"
#
#   user_data = <<-EOF
#               #!/bin/bash
#               yum update -y
#               amazon-linux-extras install docker -y
#               service docker start
#               usermod -a -G docker ec2-user
#
#               docker run -d \
#                 --name mongodb \
#                 -p 27017:27017 \
#                 -v /data/db:/data/db \
#                 mongo:latest
#             EOF
#
#   tags = {
#     Name = "mongodb-docker-server"
#   }
# }
#
# ########### GLUE  ###############
#
# # IAM Role for Glue
# resource "aws_iam_role" "glue_role" {
#   name = "GlueServiceRole"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "glue.amazonaws.com"
#         }
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }
#
# resource "aws_iam_role_policy_attachment" "glue_policy" {
#   role       = aws_iam_role.glue_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
# }
#
# # Glue Connection
# resource "aws_glue_connection" "mongo_connection" {
#   name       = "mongo-connection"
#   description = "Connection to MongoDB in EC2 Docker container"
#   connection_properties = {
#     CONNECTION_URL      = "jdbc:mongodb://<EC2_PUBLIC_IP>:27017/mongodb"
#     USERNAME            = "username" # MongoDB username if authentication is enabled
#     PASSWORD            = "password1" # MongoDB password if authentication is enabled
#   }
#
#   physical_connection_requirements {
#     subnet_id            = aws_subnet.public.id
#     security_group_id_list = [aws_security_group.mongodb_sg.id]
#     availability_zone = "eu-west-2a"
#   }
#   depends_on = [aws_security_group.mongodb_sg, aws_subnet.public]
# }
#
# # Glue Crawler
# resource "aws_glue_crawler" "mongo_crawler" {
#   name         = "mongo-crawler"
#   role         = aws_iam_role.glue_role.arn
#   database_name = "mongo_database"
#   table_prefix = "mongo_"
#
#     jdbc_target {
#       connection_name = aws_glue_connection.mongo_connection.name
#       path            = "your_mongodb_collection_name" # Replace with your MongoDB collection
#     }
# }
#
# ############ LAMBDA  #################
# # # IAM Role for Lambda
# # resource "aws_iam_role" "lambda_exec" {
# #   name = "lambda_exec_role"
# #   assume_role_policy = <<EOF
# # {
# #   "Version": "2012-10-17",
# #   "Statement": [
# #     {
# #       "Action": "sts:AssumeRole",
# #       "Principal": {
# #         "Service": "lambda.amazonaws.com"
# #       },
# #       "Effect": "Allow",
# #       "Sid": ""
# #     }
# #   ]
# # }
# # EOF
# # }
# #
# # # IAM Policy Attachment
# # resource "aws_iam_role_policy_attachment" "lambda_policy" {
# #   role       = aws_iam_role.lambda_exec.name
# #   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# # }
# #
# # # Lambda Function
# # resource "aws_lambda_function" "mongodb_lambda" {
# #   filename         = "lambda_function.zip"
# #   function_name    = "mongodb_lambda"
# #   role             = aws_iam_role.lambda_exec.arn
# #   handler          = "lambda_function.lambda_handler"
# #   runtime          = "python3.8"
# #   source_code_hash = filebase64sha256("lambda_function.zip")
# #
# #   environment {
# #     variables = {
# #       MONGO_URI = "mongodb://${aws_instance.mongodb.public_ip}:27017"
# #     }
# #   }
# # }
# #
# # # Package Lambda Code
# # data "archive_file" "lambda_package" {
# #   type        = "zip"
# #   source_dir  = "./lambda_code"
# #   output_path = "./lambda_function.zip"
# # }
# ############## LAMBDA ENDS  ########################
#
#
