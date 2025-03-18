# Create Elastic IPs regardless of NLB type
resource "aws_eip" "transfer_eip" {
  count = length(var.subnet_ids)
  tags = {
    Name        = "${var.service}-${var.environment}-transfer-eip-${count.index}"
    Environment = var.environment
    Service     = var.service
  }
}
#########
resource "aws_security_group" "sftp_server_sg" {
  name        = "${var.service}-${var.environment}-sftp-sg"
  description = "Security group for SFTP server"
  vpc_id      = var.vpc_id

  # Ingress rule to allow traffic only from the NLB
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    #security_groups = [aws_security_group.nlb_sg.id] # Reference NLB security group
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    #security_groups = [aws_security_group.nlb_sg.id] # Reference NLB security group
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule to allow all outbound traffic (adjust as needed)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.service}-${var.environment}-sftp-sg"
    Environment = var.environment
    Service     = var.service
  }
}
###############
###############
# Create the NLB
resource "aws_lb" "transfer_nlb" {
  name               = "${var.service}-${var.environment}-transfer-nlb"
  internal           = var.nlb_internal
  load_balancer_type = "network"

  dynamic "subnet_mapping" {
    for_each = toset(local.subnet_mappings) # Ensure it iterates over unique valid objects
    content {
      subnet_id     = lookup(subnet_mapping.value, "subnet_id", null)     # Always safe to access
      allocation_id = lookup(subnet_mapping.value, "allocation_id", null) # Optional allocation ID
    }
  }

  tags = {
    Name        = "${var.service}-${var.environment}-transfer-nlb"
    Environment = var.environment
    Service     = var.service
  }
}

# Create NLB Target Group
resource "aws_lb_target_group" "transfer_target_group" {
  name        = "${var.service}-${var.environment}-transfer-target-group"
  port        = 22
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol            = "TCP"
    interval            = 30
    healthy_threshold   = 3
    port                = 22
    unhealthy_threshold = 3
    timeout             = 5
  }

  tags = {
    Name        = "${var.service}-${var.environment}-transfer-target-group"
    Environment = var.environment
    Service     = var.service
  }
}

resource "aws_lb_target_group_attachment" "transfer_target_attachment" {
  count = length(data.aws_network_interface.vpc_endpoint_enis)

  target_group_arn = aws_lb_target_group.transfer_target_group.arn
  target_id        = data.aws_network_interface.vpc_endpoint_enis[count.index].private_ip
  port             = 22
}

# Create NLB Listener
resource "aws_lb_listener" "transfer_listener" {
  load_balancer_arn = aws_lb.transfer_nlb.arn
  port              = 22
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.transfer_target_group.arn
  }
}

################
resource "aws_iam_role" "transfer_logs" {
  name = "${var.service}-${var.environment}-transfer-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.service}-${var.environment}-transfer-logs-role"
    Environment = var.environment
    Service     = var.service
  }
}

resource "aws_iam_policy" "transfer_logs_policy" {
  name = "${var.service}-${var.environment}-transfer-logs-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "transfer_logs_attachment" {
  role       = aws_iam_role.transfer_logs.name
  policy_arn = aws_iam_policy.transfer_logs_policy.arn
}
#########################
resource "aws_s3_bucket" "transfer_bucket" {
  bucket = "${var.service}-${var.environment}-acsp-aml"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    Name        = "${var.service}-${var.environment}-acsp-aml"
    Environment = var.environment
    Service     = var.service
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "transfer_bucket_lifecycle" {
  bucket = aws_s3_bucket.transfer_bucket.id

  rule {
    id     = "retention-policy"
    status = "Enabled"

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_object" "transfer_folders" {
  for_each = var.sftp_users

  bucket  = aws_s3_bucket.transfer_bucket.id
  key     = "${each.key}/"
  acl     = "private"
  content = ""
}

resource "aws_s3_bucket_notification" "s3_notification" {
  for_each = var.sftp_users

  bucket = aws_s3_bucket.transfer_bucket.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_to_api.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv" # Ensure CSV files trigger the Lambda
    filter_prefix       = ""     # Ensure this matches the user's directory
  }
  depends_on = [aws_lambda_function.s3_to_api, aws_lambda_permission.s3_invoke]
}

# resource "aws_s3_bucket_policy" "acsp_aml_data_policy" {
#   bucket = aws_s3_bucket.transfer_bucket.id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid      = "AllowCSVUploads"
#         Effect   = "Allow"
#         Principal = {
#           AWS = "*"
#         }
#         Action   = "s3:PutObject"
#         Resource = "${aws_s3_bucket.transfer_bucket.arn}/*"
#         Condition = {
#           StringLike = {
#             "s3:object-key" = ["*.csv"]
#           }
#         }
#       },
#       {
#         Sid      = "DenyNonCSVUploads"
#         Effect   = "Deny"
#         Principal = {
#           AWS = "*"
#         }
#         Action   = "s3:PutObject"
#         Resource = "${aws_s3_bucket.transfer_bucket.arn}/*"
#         Condition = {
#           StringNotLike = {
#             "s3:object-key" = ["*.csv"]
#           }
#         }
#       }
#     ]
#   })
# }


#######################

resource "aws_lambda_function" "s3_to_api" {
  function_name    = "${local.resource_prefix}-s3-to-api"
  runtime          = "python3.9" # Update based on your runtime
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "s3_file.lambda_handler"         # Update as per your entrypoint
  filename         = "${path.module}/lambda_code.zip" # Ensure this path is correct
  source_code_hash = filebase64sha256("${path.module}/lambda_code.zip")
  timeout          = 30
  memory_size      = 128
  vpc_config {
    security_group_ids = [aws_security_group.lambda_sg.id]
    subnet_ids         = var.subnet_ids
  }
  environment {
    variables = {
      api_endpoint = var.invocation_endpoint
    }
  }

  tags = {
    Name        = "${local.resource_prefix}-s3-to-api"
    Environment = var.environment
    Service     = var.service
  }
}


resource "aws_lambda_permission" "s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_to_api.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.transfer_bucket.arn
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "${var.service}-${var.environment}-lambda-execution-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_policy" "lambda_execution_policy" {
  name   = "${var.service}-${var.environment}-lambda-execution-policy"
  policy = data.aws_iam_policy_document.lambda_execution_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}

resource "aws_security_group" "lambda_sg" {
  name        = "${var.service}-${var.environment}-lambda-sg"
  description = "Security group for Lambda function"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.service}-${var.environment}-lambda-sg"
    Environment = var.environment
    Service     = var.service
  }
}

###############################
resource "aws_iam_policy" "acsp_aml_user" {
  name   = "${var.service}-${var.environment}-aml-user-policy"
  policy = data.aws_iam_policy_document.transfer_user_policy.json
}

# IAM Role for Transfer Family Users and Admins
resource "aws_iam_role" "acsp_aml_user_role" {
  name               = "${var.service}-${var.environment}-aml-user-role"
  assume_role_policy = data.aws_iam_policy_document.acsp_aml_assume_role_policy.json
  tags = {
    Name        = "${var.service}-${var.environment}-ascp-aml-user-role"
    Environment = var.environment
    Service     = var.service
  }
}

resource "aws_iam_policy_attachment" "acsp_aml_policy_attachment" {
  name       = "${var.service}-${var.environment}-aml-user-policy-attachment"
  roles      = [aws_iam_role.acsp_aml_user_role.name]
  policy_arn = aws_iam_policy.acsp_aml_user.arn

}

resource "aws_transfer_server" "transfer_server" {
  identity_provider_type = "SERVICE_MANAGED"
  endpoint_type          = "VPC"
  protocols              = ["SFTP"]
  endpoint_details {
    #address_allocation_ids = aws_eip.transfer_eip.*.id
    security_group_ids = [aws_security_group.sftp_server_sg.id]
    subnet_ids         = var.subnet_ids
    vpc_id             = var.vpc_id
  }

  logging_role = aws_iam_role.transfer_logs.arn

  tags = {
    Name        = "${var.service}-${var.environment}-acsp-aml-server"
    Environment = var.environment
    Service     = var.service
  }
}

# Create SFTP Users with Logical Directory Mapping
resource "aws_transfer_user" "transfer_user" {
  for_each            = var.sftp_users
  server_id           = aws_transfer_server.transfer_server.id
  user_name           = each.key
  home_directory_type = "LOGICAL"
  role                = aws_iam_role.acsp_aml_user_role.arn

  dynamic "home_directory_mappings" {
    for_each = each.value.logical_directory_mappings
    content {
      entry  = home_directory_mappings.value.source_directory
      target = home_directory_mappings.value.user_directory
    }
  }

  tags = {
    Name        = "${var.service}-${var.environment}-acsp-aml-${each.key}"
    Environment = var.environment
    Service     = var.service
  }
}

# Dynamically Fetch SSH Keys from an External Source
resource "aws_transfer_ssh_key" "transfer_user" {
  for_each  = var.sftp_users
  server_id = aws_transfer_server.transfer_server.id
  user_name = each.key
  body      = lookup(var.ssh_public_keys, each.value.ssh_public_key, null) # Perform the lookup here

  depends_on = [aws_transfer_user.transfer_user]
}

# Dynamic SSH Key Lookup
# locals {
#   sftp_keys = jsondecode(file("${path.module}/ssh_keys.json")) # Read SSH keys from external JSON file
# }
# resource "aws_transfer_user" "transfer_user" {
#   for_each            = var.sftp_users
#   server_id           = aws_transfer_server.transfer_server.id
#   user_name           = each.key
#   home_directory_type = "LOGICAL"
#   role                = aws_iam_role.acsp_aml_user_role.arn
#
#   dynamic "home_directory_mappings" {
#     for_each = each.value.logical_directory_mappings
#     content {
#       entry  = home_directory_mappings.value.source_directory
#       target = home_directory_mappings.value.user_directory
#     }
#
#   }
#
#   tags = {
#     Name        = "${var.service}-${var.environment}-acsp-aml-${each.key}"
#     Environment = var.environment
#     Service     = var.service
#   }
# }
#
# resource "aws_transfer_ssh_key" "transfer_user" {
#   for_each  = var.sftp_users
#   server_id = aws_transfer_server.transfer_server.id
#   user_name = each.key
#   body      = chomp(file("${path.module}/ssh_aml_bodies/${each.value.ssh_public_key_files[0]}"))
#
#   depends_on = [aws_transfer_user.transfer_user]
# }

# Create a CNAME record
resource "aws_route53_record" "sftp_cname" {
  zone_id = var.route53_zone_id
  name    = "${var.subdomain}.${var.domain_name}" # Full domain name (e.g., sftp.example.com)
  type    = "CNAME"
  ttl     = 300 # Time-to-live in seconds
  records = [aws_lb.transfer_nlb.dns_name]

  depends_on = [aws_lb.transfer_nlb]
}




