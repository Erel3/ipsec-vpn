terraform {
  required_version = ">= 0.13.0"
}

provider "aws" {
  region = var.AWS_DEFAULT_REGION
}

locals {
  cidr_subnets_min = var.aws_without_private ? length(var.aws_cidr_subnets_public) : min(length(var.aws_cidr_subnets_public), length(var.aws_cidr_subnets_private))
}

module "aws-vpc" {
  source = "./vpc"

  project_name             = var.project_name
  aws_vpc_cidr_block       = var.aws_vpc_cidr_block
  aws_cidr_subnets_public  = var.aws_cidr_subnets_public
  aws_cidr_subnets_private = var.aws_cidr_subnets_private
  aws_without_private      = var.aws_without_private
  default_tags             = var.default_tags
  aws_avail_zones          = slice(data.aws_availability_zones.available.names, 0, local.cidr_subnets_min)
}


/*
* Security Groups
*
*/
resource "aws_security_group" "ipsec-vpn" {
  name   = "${var.project_name}-securitygroup"
  vpc_id = module.aws-vpc.aws_vpc_id

  tags = merge(var.default_tags, map(
    "Name", "${var.project_name}-securitygroup"
  ))
}
resource "aws_security_group_rule" "allow-all-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ipsec-vpn.id
}
resource "aws_security_group_rule" "allow-ssh-connections" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ipsec-vpn.id
}
resource "aws_security_group_rule" "allow-http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ipsec-vpn.id
}
resource "aws_security_group_rule" "allow-vpn-port-500" {
  type              = "ingress"
  from_port         = 500
  to_port           = 500
  protocol          = "UDP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ipsec-vpn.id
}
resource "aws_security_group_rule" "allow-vpn-port-4500" {
  type              = "ingress"
  from_port         = 4500
  to_port           = 4500
  protocol          = "UDP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ipsec-vpn.id
}


/*
* Create EC2 Instance
*
*/
resource "aws_instance" "ipsec-vpn" {
  ami               = data.aws_ami.distro.id
  instance_type     = var.aws_ipsec_vpn_ec2_type
  count             = length(var.aws_cidr_subnets_public)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  subnet_id         = element(module.aws-vpc.aws_subnet_ids_public, count.index)

  vpc_security_group_ids = aws_security_group.ipsec-vpn.*.id

  key_name = var.AWS_SSH_KEY_NAME

  tags = merge(var.default_tags, map(
    "Name", "${var.project_name}-${count.index}",
    "Cluster", "${var.project_name}",
    "Role", "main-${count.index}"
  ))
}
resource "aws_eip" "ipsec-vpn-eip" {
  count    = length(var.aws_cidr_subnets_public)
  instance = element(aws_instance.ipsec-vpn, count.index).id
  vpc      = true
}

/*
* Create Inventory File For Ansible
*
*/
data "template_file" "inventory" {
  template = file("${path.module}/templates/inventory.tpl")

  vars = {
    key_name = var.AWS_SSH_KEY_NAME
    instance_user = var.aws_ec2_user
    public_ip_address_ipsec_vpn = join("\n", formatlist("%s ansible_host=%s", aws_instance.ipsec-vpn.*.private_dns, aws_eip.ipsec-vpn-eip.*.public_ip))
    ipsec_hosts                 = join("\n", formatlist("%s", aws_instance.ipsec-vpn.*.private_dns))
  }
}
resource "null_resource" "inventories" {
  provisioner "local-exec" {
    command = "echo '${data.template_file.inventory.rendered}' > ${var.inventory_file}"
  }

  triggers = {
    template = data.template_file.inventory.rendered
  }
}
