##General
project_name = "ipsec-vpn"

##VPC Vars
aws_vpc_cidr_block = "10.69.0.0/16"
#subnets for each availability zone in VPC
aws_cidr_subnets_private = ["10.69.0.0/18"]  # ["10.69.0.0/18", "10.69.128.0/18"]
aws_cidr_subnets_public  = ["10.69.64.0/18"] # ["10.69.64.0/18", "10.69.192.0/18"]
aws_without_private      = true              # set true if you don't want to use NAT (~30$/month) for each availability zone

##EC2 Vars
aws_ipsec_vpn_ec2_type = "t2.micro"
aws_ec2_user = "ubuntu"

##TAGs
default_tags = {
  Env     = "ipsec-prod"
  Product = "ipsec-vpn"
}
inventory_file = "../ansible/inventory/hosts"
