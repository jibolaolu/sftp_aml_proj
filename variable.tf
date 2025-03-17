variable "region" {

}


variable "environment" {
  description = "The name of the infrastructure 'stack' this infrastructure is part of."
  type        = string
}

variable "aws_profile" {
  description = "AWS profile to use for deployment"
  type        = string
}

variable "service" {
  description = "The service name to be used when creating AWS resources"
  type        = string
}



variable "default_tags" {
  description = "A map of default tags to be added to the resources"
  type        = map(any)
  default     = {}
}

variable "sftp_users" {
  description = "Map of SFTP users to their SSH key file paths and admin flag"
  type = map(object({
    logical_directory_mappings = list(object({
      source_directory = string
      user_directory   = string
    }))
    ssh_public_key_files = list(string)
    is_admin             = bool
  }))
  default = {}
}

variable "invocation_endpoint" {
  description = "The ARN of the endpoint where the S3 events should be sent (e.g., Lambda, SNS)"
  type        = string
}

# Variables
# variable "vpc_id" {}
# variable "subnet_id" {}
# variable "security_group_id" {}

variable "nlb_internal" {
  description = "Set to true if the NLB is internal, false for internet-facing"
  type        = bool
}

variable "subnet_ids" {
  description = "List of subnet IDs for the NLB"
  type        = list(string)
}


variable "vpc_id" {
  description = "VPC ID for the resources"
  type        = string
}

# Variables for customization
variable "domain_name" {
  description = "The domain name to map to the NLB."
  type        = string
}

variable "subdomain" {
  description = "The subdomain for the SFTP server."
  type        = string
}

# variable "nlb_dns_name" {
#   description = "The DNS name of the NLB."
#   type        = string
# }

# Route 53 Zone ID
variable "route53_zone_id" {
  description = "The ID of the Route 53 hosted zone for the domain."
  type        = string
}

# variable "user_directory_prefix" {
#   type = string
# }

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  default     = "ecs-demo-cluster"
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  default     = "ecs-demo-service"
}

variable "container_image" {
  description = "Docker image to run on ECS"
  default     = "jibolaolu/ecstos3:latest" # Replace with your image
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  default     = "ecs-demo-bucket"
}

variable "sftp_keys_json" {
  description = "JSON mapping of SFTP users to their SSH keys"
  type        = string
}





