data "aws_iam_policy_document" "transfer_user_policy" {
  statement {
    sid    = "AllowUserListUploadReadWritetoBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:GetBucketLocation"
    ]
    resources = [aws_s3_bucket.transfer_bucket.arn,
    "${aws_s3_bucket.transfer_bucket.arn}/*"]
  }
}

# data "aws_iam_policy_document" "acsp_aml_user_policy" {
#   statement {
#     sid    = "AllowUserListUploadReadWritetoBucket"
#     effect = "Allow"
#     actions = [
#       "s3:ListBucket",
#       "s3:PutObject",
#       "s3:GetObject",
#       "s3:DeleteObject",
#       "s3:GetBucketLocation"
#     ]
#     resources = [aws_s3_bucket.transfer_bucket.arn,
#       "${aws_s3_bucket.transfer_bucket.arn}/*"]
#   }
# }

data "aws_iam_policy_document" "acsp_aml_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "acsp_aml_data" {
  statement {
    sid    = "AllowConcoursePutObject"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.transfer_bucket.arn}/*"
    ]
  }

  statement {
    sid    = "DenyNonCSVUploads"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.transfer_bucket.arn}/*"
    ]

    condition {
      test     = "StringNotLike"
      variable = "s3:Key"
      values   = ["*.csv"]
    }
  }
}



# Assume Role Policy for S3 to assume
data "aws_iam_policy_document" "s3_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    effect = "Allow"
  }
}

# Fetch the current AWS region
data "aws_region" "current" {}

# Fetch the current AWS account ID
data "aws_caller_identity" "current" {}

# #Fetch the VPC endpoint associated with the SFTP server
data "aws_vpc_endpoint" "sftp_vpc_endpoint" {
  count  = length(aws_transfer_server.transfer_server.endpoint_details)
  id     = aws_transfer_server.transfer_server.endpoint_details[count.index].vpc_endpoint_id
  vpc_id = var.vpc_id
}


locals {
  eni_ids = flatten([
    for i in range(0, length(aws_transfer_server.transfer_server.endpoint_details)) :
    data.aws_vpc_endpoint.sftp_vpc_endpoint[i].network_interface_ids
  ])
}

data "aws_network_interface" "vpc_endpoint_enis" {
  count = length(var.subnet_ids)
  id    = local.eni_ids[count.index]
}

data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "./lambda_code1"
  output_path = "./lambda_code_out.zip"
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_execution_policy" {
  statement {
    sid    = "AllowLogsAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid    = "AllowS3Access"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.transfer_bucket.arn,
      "${aws_s3_bucket.transfer_bucket.arn}/*"
    ]
  }

  statement {
    sid    = "AllowVpcNetworkAccess"
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface"
    ]
    resources = ["*"]
  }
}

# data "aws_network_interface" "sftp_eni_private_ips" {
#   for_each = flatten([for vpc_endpoint in data.aws_vpc_endpoint.sftp_vpc_endpoint : vpc_endpoint.network_interface_ids])
#   id       = each.value
# }
# data "aws_network_interface" "sftp_eni_private_ips" {
#   for_each = toset(local.sftp_network_interface_ids)
#   id       = each.value
# }

# locals {
#   # Collect all network_interface_ids
#   sftp_network_interface_ids = flatten([
#     for vpc_endpoint in data.aws_vpc_endpoint.sftp_vpc_endpoint :
#     vpc_endpoint.network_interface_ids
#   ])
# }
#
# data "aws_network_interface" "sftp_eni_private_ips" {
#   count = length(local.sftp_network_interface_ids)
#   id    = local.sftp_network_interface_ids[count.index]
# }

# output "sftp_private_ips" {
#   value = [for eni in range(0, length(aws_transfer_server.transfer_server.endpoint_details)): data.aws_vpc_endpoint.sftp_vpc_endpoint[eni].network_interface_ids]
# }

# output "sftp_private_ips_" {
#   value = [for eni in data.aws_network_interface.sftp_eni_private_ips : eni.private_ip]
# }


