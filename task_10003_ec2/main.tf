provider "aws" {

region = var.region

access_key = var.access_key

secret_key = var.secret_key

}

data "aws_ssm_parameter" "al2023_latest" {

name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"

}

resource "aws_s3_bucket" "blog" {

bucket = var.bucket_name

}

resource "aws_s3_object" "object1" {

for_each = fileset("html/", "*")

bucket = aws_s3_bucket.blog.id

key = each.value

source = "html/${each.value}"

etag = filemd5("html/${each.value}")

content_type = "text/html"

}

resource "aws_security_group" "web-sg" {

name = "Web-SG"

 ingress {

 from_port = 80

 to_port = 80

 protocol = "tcp"

 cidr_blocks = ["0.0.0.0/0"]

 }

 ingress {

 from_port = 443

 to_port = 443

 protocol = "tcp"

 cidr_blocks = ["0.0.0.0/0"]

 }

 egress {

 from_port = 0

 to_port = 0

 protocol = "-1"

 cidr_blocks = ["0.0.0.0/0"]

 }
}

 resource "aws_instance" "web" {
  ami                    = data.aws_ssm_parameter.al2023_latest.value
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  iam_instance_profile   = "EC2SSMManagedRoleProfile-5d071386"

  user_data = <<EOF
#!/bin/bash
sudo su
yum update -y
yum install httpd -y
aws s3 cp s3://${aws_s3_bucket.blog.id}/index.html /var/www/html/index.html
systemctl start httpd
systemctl enable httpd
EOF

  tags = {
    Name = "Whiz-EC2-Instance"
  }
}