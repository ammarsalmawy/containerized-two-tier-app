
provider "aws" {
  region = "us-east-1"
}


resource "aws_ecr_repository" "webapp" {
  name = "webapp"
}

resource "aws_ecr_repository" "mysql" {
  name = "mysql"
}


data "aws_vpc" "default" {
  default = true
}


data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}



data "aws_iam_instance_profile" "ec2_profile" {
  name = "LabInstanceProfile"
}

# Security group for EC2
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8083
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
resource "aws_key_pair" "ec2_key" {
  key_name   = "my-key"
  public_key = file("my-key.pub")
}

# Launch EC2 instance
resource "aws_instance" "app_server" {
  ami                    = "ami-0c02fb55956c7d316" 
  instance_type          = "t2.micro"
  subnet_id              = element(data.aws_subnets.public.ids, 0) 
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = data.aws_iam_instance_profile.ec2_profile.name

  key_name = aws_key_pair.ec2_key.key_name
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras enable docker
              sudo yum install docker -y
              sudo service docker start
              sudo usermod -aG docker ec2-user
              sudo systemctl enable docker
            EOF
  tags = {
    Name = "Assignment1-EC2"
  }
}