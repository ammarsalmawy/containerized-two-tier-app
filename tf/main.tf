# Configure AWS provider
provider "aws" {
  region = "us-east-1" # Update your region
}

# Create ECR repositories
resource "aws_ecr_repository" "webapp" {
  name = "webapp"
}

resource "aws_ecr_repository" "mysql" {
  name = "mysql"
}

# Fetch default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch public subnets in default VPC
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# # Create IAM role for EC2 to access ECR
# resource "aws_iam_role" "ec2_ecr_access" {
#   name = "ec2-ecr-access-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Action = "sts:AssumeRole",
#       Effect = "Allow",
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       }
#     }]
#   })
# }

# # Attach ECR read-only policy to the role
# resource "aws_iam_role_policy_attachment" "ecr_access" {
#   role       = aws_iam_role.ec2_ecr_access.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
# }

# Create EC2 instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ecr-profile"
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
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI (update if needed)
  instance_type          = "t2.micro"
  subnet_id              = element(data.aws_subnets.public.ids, 0) # Use first public subnet
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  key_name = aws_key_pair.ec2_key.key_name

  tags = {
    Name = "Assignment1-EC2"
  }
}