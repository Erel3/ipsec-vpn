variable "AWS_SSH_KEY_NAME" {
  description = "Name of the SSH keypair to use in AWS."
}

variable "AWS_DEFAULT_REGION" {
  description = "AWS Region"
}

/*
* General Settings
*
*/
variable "project_name" {
  description = "Project name. will be used in all resource names"
}

data "aws_ami" "distro" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_availability_zones" "available" {}

/*
* AWS VPC Variables
*
*/
variable "aws_vpc_cidr_block" {
  description = "CIDR Block for VPC"
}

variable "aws_cidr_subnets_private" {
  description = "CIDR Blocks for private subnets in Availability Zones"
  type        = list
}

variable "aws_cidr_subnets_public" {
  description = "CIDR Blocks for public subnets in Availability Zones"
  type        = list
}

variable "aws_without_private" {
  description = "Do not use private subnet and NAT(~30$/month)"
  type        = bool
}

/*
* EC2 Variables
*
*/
variable "aws_ipsec_vpn_ec2_type" {
  description = "Instance type"
}

variable "aws_ec2_user" {
  description = "ec2-instance-user"
}

/*
* TAGs
*
*/
variable "default_tags" {
  description = "Default tags for all resources"
  type        = map
}

/*
* Inventory File
*
*/
variable "inventory_file" {
  description = "Where to store the generated inventory file"
}
