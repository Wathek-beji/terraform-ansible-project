# terraform-ansible-project

A personal project created to learn infrastructure provisioning using Terraform and the libvirt-provider plugin and config management using Ansible. 

## Infrastructure provisionning

This project uses Terraform and the libvirt-provider plugin to provision 4 VMs each with a static ip address. 
The code and configurations for the infrastructure provisioning is found under terraform-source/

## Config management

The ansible playbook config-resources.yml under ansible-source triggers the execution of 3 roles
1/dns: deploys a bind dns server
2/apache: deploys a apache http server
3/loadbalancer: deploys a haproxy loadbalancer


