terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name    = var.project_tag
    project = var.project_tag
  }
}

# 公有子网
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_1"
    project = var.project_tag
  }
}

# 私有子网
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name    = "private_subnet_1"
    project = var.project_tag
  }
}

# 创建Internet gateway
resource "aws_internet_gateway" "igw1" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    project = var.project_tag
  }
}

# 为vpc创建route table，并初始化好路由规则
resource "aws_route_table" "RouteTablePublic" {
  vpc_id     = aws_vpc.vpc.id
  depends_on = [aws_internet_gateway.igw1]
  tags = {
    # Name    = "${var.vpc_name}-public-route-table"
    project = var.project_tag
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw1.id
  }
}

# 绑定subnet和路由表
resource "aws_route_table_association" "AssociationForRouteTablePublic0" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.RouteTablePublic.id
}

# 创建EIP
resource "aws_eip" "EIPNAT1" {
  tags = {
    # Name    = "${var.vpc_name}-EIP-NAT1"
    project = var.project_tag
  }
}

# 创建nat gateway
resource "aws_nat_gateway" "NATGW1" {
  subnet_id         = aws_subnet.public_subnet_1.id
  connectivity_type = "public"
  allocation_id     = aws_eip.EIPNAT1.id
  tags = {
    Name    = "NATGW1"
    project = var.project_tag
  }
}

# 创建私网路由表
resource "aws_route_table" "RouteTablePrivate1" {
  vpc_id     = aws_vpc.vpc.id
  depends_on = [aws_nat_gateway.NATGW1]
  tags = {
    # Name    = "${var.vpc_name}-private-route-table-1"
    project = var.project_tag
  }
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NATGW1.id
  }
}
# 绑定subnet和路由表
resource "aws_route_table_association" "AssociationForRouteTablePrivate1a" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.RouteTablePrivate1.id
}

# s3 endpoint
resource "aws_vpc_endpoint" "endpoint_s3" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  tags = {
    project = var.project_tag
  }
}
# s3 endpoint 添加到路由表
resource "aws_vpc_endpoint_route_table_association" "routeToS3_1" {
  route_table_id  = aws_route_table.RouteTablePublic.id
  vpc_endpoint_id = aws_vpc_endpoint.endpoint_s3.id
}
resource "aws_vpc_endpoint_route_table_association" "routeToS3_2" {
  route_table_id  = aws_route_table.RouteTablePrivate1.id
  vpc_endpoint_id = aws_vpc_endpoint.endpoint_s3.id
}

resource "aws_security_group" "public_sg" {
  name        = "public_sg"
  description = "default security group for public subnet"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "icmp"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    project = var.project_tag
    name    = "public_sg"
  }
}


resource "aws_security_group" "private_sg" {
  name        = "private_sg"
  description = "default security group for private subnet"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }

  ingress {
    description = "mysql"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    # cidr_blocks      = [aws_vpc.vpc.cidr_block]
    security_groups = [aws_security_group.public_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    project = var.project_tag
    Name    = "private_sg"
  }
}

resource "aws_instance" "app_server" {
  ami           = var.ami
  instance_type = var.instance_type

  tags = {
    Name    = var.instance_name
    project = var.project_tag
  }

  subnet_id              = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  key_name               = "from-mac"

  root_block_device {
    volume_size           = 50
    volume_type           = "gp3"
    delete_on_termination = true
    tags = {
      project = var.project_tag
    }
  }

  # ebs_block_device {
  #   device_name = "/dev/sdb"
  #   delete_on_termination = true
  # }

  user_data = <<-EOF
    #!/bin/bash
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
    sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
    wget https://developer.download.nvidia.com/compute/cuda/12.1.0/local_installers/cuda-repo-ubuntu2204-12-1-local_12.1.0-530.30.02-1_amd64.deb
    sudo dpkg -i cuda-repo-ubuntu2204-12-1-local_12.1.0-530.30.02-1_amd64.deb
    sudo cp /var/cuda-repo-ubuntu2204-12-1-local/cuda-*-keyring.gpg /usr/share/keyrings/
    sudo apt-get update
    sudo apt-get -y install cuda
    sudo apt -y install python3-pip
    # for 
    pip3 install fschat
EOF

}
