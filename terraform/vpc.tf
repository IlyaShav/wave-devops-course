terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}
provider "aws" {
  profile = "default"
  region  = "us-east-1"
  shared_credentials_file = "/home/$USER/.aws/credentials"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "infra-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.6.0/24", "10.0.4.0/24", "10.0.5.0/24"]

  enable_ipv6 = false

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    Name = "public"
  }
  
  private_subnet_tags = {
    Name = "private"
  }
  
  enable_dns_hostnames = true
  
}

module "public_security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "public"
  description = "internet access"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "User-service ports"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "User-service ports "
      cidr_blocks = "0.0.0.0/0"
    },
  ]

}

module "private_security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "private"
  description = "vpc access only"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "User-service ports"
      cidr_blocks = "10.0.0.0/16"
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "User-service ports "
      cidr_blocks = "0.0.0.0/0"
    },
  ]

}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "public"

  ami                    = "ami-09e67e426f25ce0d7"
  instance_type          = "t2.micro"
  key_name               = "Nvirg"
  vpc_security_group_ids = [module.public_security_group.security_group_id]
  iam_instance_profile   = "ansible-admin"
  subnet_id              = module.vpc.public_subnets[0] 
  user_data              = <<-EOT
#!/bin/bash
apt update -y 
apt install ansible -y 
apt install python3-pip -y
pip3 install boto3
cd /opt/
mkdir ansible
cd /opt/ansible
mkdir inventory
cd /opt/ansible/inventory
touch aws_ec2.yaml
cat << EOF >> aws_ec2.yaml
---
plugin: aws_ec2

keyed_groups:
  - key: tags
    prefix: tag
EOF
cd /etc/ansible
cat << EOF > ansible.cfg
[inventory]
enable_plugins = aws_ec2
[defaults]
inventory      = /opt/ansible/inventory/aws_ec2.yaml
EOF
chown -R ubuntu:ubuntu /etc/ansible
cd /
mkdir ansible 
cd ansible/ 
cat << EOF > playbook.yaml
---
- hosts: tag_Name_private
  become: true

  tasks:
    - name: Install aptitude using apt
      apt: name=aptitude state=latest update_cache=yes force_apt_get=yes

    - name: Install required system packages
      apt: name={{ item }} state=latest update_cache=yes
      loop: [ 'apt-transport-https', 'ca-certificates', 'curl', 'software-properties-common', 'python3-pip', 'virtualenv', 'python3-setuptools']

    - name: Add Docker GPG apt Key
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: Add Docker Repository
      apt_repository:
        repo: deb https://download.docker.com/linux/ubuntu bionic stable
        state: present

    - name: Update apt and install docker-ce
      apt: update_cache=yes name=docker-ce state=latest

    - name: Install Docker Module for Python
      pip:
        name: docker

    - name: Pull default Docker image
      docker_image:
        name: httpd
        source: pull

    # Creates the number of containers defined by the variable create_containers, using values from vars file
    - name: Create nginx containers
      docker_container:
        name: "static_website"
        image: httpd
        state: started
        published_ports: "80:80"
EOF
EOT
}

module "ec2_instance_private1" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "private"

  ami                    = "ami-09e67e426f25ce0d7"
  instance_type          = "t2.micro"
  key_name               = "Nvirg"
  vpc_security_group_ids = [module.private_security_group.security_group_id]
  subnet_id              = module.vpc.private_subnets[1]
}

module "ec2_instance_private2" {                                                                                   
  source  = "terraform-aws-modules/ec2-instance/aws"                                                               
  version = "~> 3.0"                                                                                               
                                                                                                                   
  name = "private"                                                                                                 
                                                                                                                   
  ami                    = "ami-09e67e426f25ce0d7"                                                                 
  instance_type          = "t2.micro"                                                                              
  key_name               = "Nvirg"                                                                                 
  vpc_security_group_ids = [module.private_security_group.security_group_id]                                       
  subnet_id              = module.vpc.private_subnets[2]                                                           
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = "my-alb"

  load_balancer_type = "application"

  vpc_id             = module.vpc.vpc_id
  subnets            = [module.vpc.public_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
  security_groups    = [module.public_security_group.security_group_id]


  target_groups = [
    {
      name_prefix      = "pref-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      targets = [
        {
          target_id = module.ec2_instance_private2.id
          port = 80
        },
        {
          target_id = module.ec2_instance_private1.id
          port = 80
        }
      ]
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

}


