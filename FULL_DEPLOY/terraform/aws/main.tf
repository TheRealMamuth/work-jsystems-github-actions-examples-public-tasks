provider "aws" {
  region = var.region
  default_tags {
    tags = { Project = var.name, ManagedBy = "Terraform" }
  }
}

# Canonical publishes this parameter in each supported AWS region.
data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

resource "aws_vpc" "app" {
  cidr_block           = "10.77.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = var.name }
}

resource "aws_subnet" "app" {
  vpc_id     = aws_vpc.app.id
  cidr_block = "10.77.1.0/24"
  tags       = { Name = "${var.name}-public" }
}

resource "aws_internet_gateway" "app" {
  vpc_id = aws_vpc.app.id
}

resource "aws_route_table" "app" {
  vpc_id = aws_vpc.app.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app.id
  }
}

resource "aws_route_table_association" "app" {
  subnet_id      = aws_subnet.app.id
  route_table_id = aws_route_table.app.id
}

resource "aws_security_group" "app" {
  name_prefix = "${var.name}-"
  description = "Application and SSH from the current deployment runner"
  vpc_id      = aws_vpc.app.id
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = var.ssh_cidr
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = var.app_cidr
  ip_protocol       = "tcp"
  from_port         = var.app_port
  to_port           = var.app_port
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_key_pair" "deploy" {
  key_name   = "${var.name}-deploy"
  public_key = tls_private_key.deploy.public_key_openssh
}

resource "aws_instance" "app" {
  ami                         = nonsensitive(data.aws_ssm_parameter.ubuntu_ami.value)
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.app.id
  key_name                    = aws_key_pair.deploy.key_name
  vpc_security_group_ids      = [aws_security_group.app.id]
  user_data_replace_on_change = true
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  root_block_device {
    volume_size           = 12
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }
  user_data = "#cloud-config\n${yamlencode({
    ssh_pwauth     = false
    ssh_deletekeys = true
    ssh_keys = {
      ed25519_private = tls_private_key.host.private_key_openssh
      ed25519_public  = trimspace(tls_private_key.host.public_key_openssh)
    }
  })}"
  tags = { Name = var.name }
}

resource "aws_eip" "app" {
  domain     = "vpc"
  instance   = aws_instance.app.id
  depends_on = [aws_internet_gateway.app, aws_route_table_association.app]
}
