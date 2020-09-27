[all:vars]
ansible_user=${instance_user}
ansible_ssh_private_key_file=/home/mika/work/keys/${key_name}.pem
[all]
${public_ip_address_ipsec_vpn}

[ipsec_vpn]
${ipsec_hosts}
