# Setting up strongswan ipsec vpn with static ip for users

## Prerequisites

  - [aws-cli][1]
  - [terraform][2] (>= 0.13.0)
  - [ansible][3]

[1]: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html "aws-cli"
[2]: https://learn.hashicorp.com/tutorials/terraform/install-cli "terraform"
[3]: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html "ansible"

## Step 1: Creating aws instance using terraform

Set values in **terraform/credentials.tfvars**. Then run:

```bash
cd terraform
terraform apply -auto-approve -var-file=credentials.tfvars
cd ..
```

## Step 2: Setting up VPN

Set values in **ansible/vars/config.yaml**. Then run:
```bash
cd ansible
ansible-playbook -i inventory/hosts ipsec-vpn.yml
cd ..
```

## Step 3: Configure clients

### Android

Download [strongSwan VPN Client](https://play.google.com/store/apps/details?id=org.strongswan.android) from Google Play.

### Linux

Install [networkmanager-strongswan](https://wiki.strongswan.org/projects/strongswan/wiki/NetworkManager).

### Windows

Just set up a new VPN connection.

## Done!

## Uninstalling

```bash
cd terraform
terraform destroy -auto-approve -var-file=credentials.tfvars
cd ..
```
