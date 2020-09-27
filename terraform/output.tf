output "ec2-instance-ips" {
  value = aws_eip.ipsec-vpn-eip.*.public_ip
}

output "inventory" {
  value = data.template_file.inventory.rendered
}
