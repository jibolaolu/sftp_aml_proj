# resource "aws_vpc" "Project_VPC" {
#   cidr_block           = "10.9.0.0/16"
#   enable_dns_hostnames = "true"
#   enable_dns_support   = "true"
#
#   tags = {
#     Name = "Project_VPC"
#   }
# }
#
# resource "aws_internet_gateway" "Project_IGW" {
#   vpc_id = aws_vpc.Project_VPC.id
#
#   tags = {
#     Name = "Project_IGW"
#   }
# }
#
# resource "aws_eip" "Monitor_EIP" {
#   vpc = true
#
#   tags = {
#     Name = "Monitor_EIP"
#   }
# }
#
# resource "aws_nat_gateway" "Monitor_NGW" {
#   allocation_id = aws_eip.Monitor_EIP.id
#   subnet_id     = aws_subnet.Project_Public_Subnet1.id
# }
# resource "aws_subnet" "Project_Public_Subnet1" {
#   cidr_block              = "10.9.1.0/24"
#   vpc_id                  = aws_vpc.Project_VPC.id
#   availability_zone       = "eu-west-2a"
#   map_public_ip_on_launch = "true"
#
#   tags = {
#     Name = "Project_Public_Subnet1"
#   }
# }
#
# resource "aws_subnet" "Project_Subnet3" {
#   cidr_block = "10.9.5.0/24"
#   vpc_id = aws_vpc.Project_VPC.id
#   availability_zone = "eu-west-2a"
#   map_public_ip_on_launch = true
#   tags = {
#     Name = "Project_Public_Subnet3"
#   }
# }
#
# resource "aws_subnet" "Project_Public_Subnet2" {
#   cidr_block              = "10.9.2.0/24"
#   vpc_id                  = aws_vpc.Project_VPC.id
#   availability_zone       = "eu-west-2b"
#   map_public_ip_on_launch = "true"
#
#   tags = {
#     Name = "Project_Public_Subnet2"
#   }
# }
#
# resource "aws_subnet" "Project_Private_Subnet" {
#   cidr_block        = "10.9.3.0/24"
#   vpc_id            = aws_vpc.Project_VPC.id
#   availability_zone = "eu-west-2c"
#
#   tags = {
#     Name = "Project_Private_Subnet1"
#   }
# }
# resource "aws_subnet" "Project_Private_Subnet2" {
#   cidr_block        = "10.9.4.0/24"
#   vpc_id            = aws_vpc.Project_VPC.id
#   availability_zone = "eu-west-2b"
#
#   tags = {
#     Name = "Project_Private_Subnet2"
#   }
# }
#
# resource "aws_route_table" "Project_Public_Route_Table" {
#   vpc_id = aws_vpc.Project_VPC.id
#
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.Project_IGW.id
#   }
#
#   tags = {
#     Name = "Project_Public_Route_Table"
#   }
# }
#
# resource "aws_route_table" "Project_Public_Route_Table1" {
#   vpc_id = aws_vpc.Project_VPC.id
#
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.Project_IGW.id
#   }
#
#   tags = {
#     Name = "Project_Public_Route_Table"
#   }
# }
#
# resource "aws_route_table_association" "Project_PublicRT_Association1" {
#   route_table_id = aws_route_table.Project_Public_Route_Table.id
#   subnet_id      = aws_subnet.Project_Public_Subnet1.id
# }
#
# resource "aws_route_table_association" "Project_PublicRT_Association2" {
#   route_table_id = aws_route_table.Project_Public_Route_Table1.id
#   subnet_id      = aws_subnet.Project_Public_Subnet2.id
# }
