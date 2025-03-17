# sftp_users = {
#   "sftp_user1" = {
#     logical_directory_mappings = [
#       {
#         source_directory = "/sftp_user1"     # This would be the Entry in the code, where the external lands when they log in
#         user_directory   = "/sftp-dev-acsp-aml/sftp_user1" #This is where User uploads files to be processed.
#       }
#     ]
#     ssh_public_key_files = ["sftp_user1.pub"]
#     is_admin             = false
#   },
#   "sftp_user2" = {
#     logical_directory_mappings = [
#       {
#         source_directory = "/sftp_user2"
#         user_directory   = "/sftp-dev-acsp-aml/sftp_user2"
#       }
#     ]
#     ssh_public_key_files = ["sftp_user2.pub"]
#     is_admin             = false
#   },
#   "sftp_user3" = {
#     logical_directory_mappings = [
#       {
#         source_directory = "/sftp_user3"
#         user_directory   = "/sftp-dev-acsp-aml/sftp_user3"
#       }
#     ]
#     ssh_public_key_files = ["sftp_user3.pub"]
#     is_admin             = false
#   },
#   "sftp_admin" = {
#     logical_directory_mappings = [
#       {
#         source_directory = "/"
#         user_directory   = "/sftp-dev-acsp-aml"
#       }
#     ]
#     ssh_public_key_files = ["sftp_admin.pub"]
#     is_admin             = true
#   }
# }

service     = "sftp"
environment = "dev"

invocation_endpoint = "https://webhook.site/1cb4916c-3cdc-4de6-a126-cd79c493142f"
aws_profile         = "default"

subnet_ids = ["subnet-05de720533f5ab06e", "subnet-0ef11b9e27004b50b"]

vpc_id = "vpc-0033c72e0464565f5"

nlb_internal = false

domain_name     = "eaglesoncloude.com"
subdomain       = "sftp"
#nlb_dns_name    = "sftp-dev-transfer-nlb-97232fb12dc4a473.elb.eu-west-2.amazonaws.com"
route53_zone_id = "Z093721723YGO5T9U48BI"
region = "eu-west-2"

# user_directory_prefix = "sftp-dev-acsp-aml"
# sftp_users = ["sftp_user1", "sftp_user2", "sftp_user3", "sftp_admin"]


sftp_users = {
  "sftp_user1" = {
    logical_directory_mappings = [
      {
        source_directory = "/sftp_user1"
        user_directory   = "/sftp-dev-acsp-aml/sftp_user1"
      }
    ]
    ssh_public_key = "sftp_user1"
    is_admin       = false
  },
  "sftp_user2" = {
    logical_directory_mappings = [
      {
        source_directory = "/sftp_user2"
        user_directory   = "/sftp-dev-acsp-aml/sftp_user2"
      }
    ]
    ssh_public_key = "sftp_user2"
    is_admin       = false
  },
  "sftp_user3" = {
    logical_directory_mappings = [
      {
        source_directory = "/sftp_user3"
        user_directory   = "/sftp-dev-acsp-aml/sftp_user2"
      }
    ]
    ssh_public_key = "sftp_user3"
    is_admin       = false
  },
  "sftp_admin" = {
    logical_directory_mappings = [
      {
        source_directory = "/"
        user_directory   = "/sftp-dev-acsp-aml"
      }
    ]
    ssh_public_key = "sftp_admin"
    is_admin       = true
  }
}


