terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.43.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}


resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
}

module "sg" {
  source = "git::https://github.com/mahimasharu2208/terraform-aws-sg.git?ref=v1.0.0"
  vpc_id = aws_vpc.main.id
}

module "ec2" {
  source            = "git::https://github.com/mahimasharu2208/terraform-aws-ec2.git?ref=v1.0.0"
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  private_subnet_id = aws_subnet.private.id
  ec2_sg_id         = module.sg.ec2_sg_id
}

module "alb" {
  source             = "git::https://github.com/mahimasharu2208/terraform-aws-alb.git?ref=v1.0.0"
  public_subnet_ids  = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  vpc_id             = aws_vpc.main.id
  alb_sg_id          = module.sg.alb_sg_id
  target_instance_id = module.ec2.instance_id
}