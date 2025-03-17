locals {
  common_tags = {
    Service     = var.service
    Environment = var.environment
    Provisioner = "Terraform"
  }
  resource_prefix = "${var.service}-${var.environment}"

  sftp_keys = jsondecode(file("ssh_keys.json"))  # Read SSH keys from Jenkins-injected JSON
}

locals {
  # Subnet mappings for internal NLB
  internal_subnet_mappings = [for subnet_id in var.subnet_ids : { subnet_id = subnet_id }]

  # Subnet mappings for internet-facing NLB
  internet_subnet_mappings = var.nlb_internal ? [] : [for idx, subnet_id in var.subnet_ids : { subnet_id = subnet_id, allocation_id = aws_eip.transfer_eip[idx].id }]

  # Use the appropriate subnet mappings based on the NLB type
  subnet_mappings = var.nlb_internal ? local.internal_subnet_mappings : local.internet_subnet_mappings
}
