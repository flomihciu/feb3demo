provider "aws" {
  region = "us-east-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}
resource "aws_security_group" "web_sg" {
  name        = "flo-exam2-sg"
  description = "Allow inbound HTTP, SSH, and PostgreSQL traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "flo-sg"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "172.15.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "flo-vpc"
  }
}

resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.15.2.0/24"  
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.15.3.0/24" 
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "main_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.15.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
}

resource "aws_route_table_association" "main_route_association" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id
}

resource "aws_instance" "target_node" {
  ami                    = "ami-0669774ba23136180"
  instance_type          = "t2.micro"
  subnet_id             = aws_subnet.main_subnet.id
  security_groups       = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  key_name              = "flo-east1"
  tags = {
    Name = "flo-target-node"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "public_ip" {
  instance = aws_instance.target_node.id
}

resource "aws_key_pair" "deployer_key" {
  key_name   = "deployer-key"
  public_key = file("/home/flomihciu/devops/tfdocker/flo-east1.pub")
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.target_node.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.target_node.private_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.target_node.id
}

output "elastic_ip" {
  description = "Elastic IP assigned to the EC2 instance"
  value       = aws_eip.public_ip
}
