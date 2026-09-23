terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

# Generate SSH Key Pair
resource "tls_private_key" "whizlabs_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Import Public Key to AWS
resource "aws_key_pair" "whizlabs_key" {
  key_name   = "whizlabs-key"
  public_key = tls_private_key.whizlabs_key.public_key_openssh
}

# Save Private Key Locally
resource "local_file" "private_key" {
  filename        = "${path.module}/whizlabs-key.pem"
  content         = tls_private_key.whizlabs_key.private_key_pem
  file_permission = "0400"
}

# Security Group
resource "aws_security_group" "web-server" {

  name        = "web-server"
  description = "Allow incoming HTTP Connections"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "web-server" {
ami = "ami-0150ccaf51ab55a51"
instance_type = "t2.micro"
key_name = "whizlabs-key"
security_groups = ["${aws_security_group.web-server.name}"]
user_data = <<-EOF
#!/bin/bash 
sudo su
yum update -y
yum install httpd -y
systemctl start httpd
systemctl enable httpd
echo "<html><h1> Welcome to Whizlabs. Happy Learning... Enjoy....</h1></html>" >> /var/www/html/index.html       
EOF 
tags = {
Name = "web_instance"           
}           
}