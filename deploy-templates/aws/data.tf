data "aws_nat_gateway" "cluster_ip" {
  filter {
    name   = "tag:Name"
    values = ["${var.cluster_name}*"]
  }
}

data "http" "external_ip" {
  url = "http://ipv4.icanhazip.com"
}

data "aws_ami" "ubuntu" {
  most_recent = "true"
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["vault-kms-unseal-${var.cluster_name}*"]
  }
}

data "aws_internet_gateway" "gw" {
  filter {
    name   = "tag:Name"
    values = ["vault-kms-unseal-${var.cluster_name}*"]
  }
}

data "aws_subnet" "public_subnet" {
  filter {
    name   = "tag:Name"
    values = ["vault-kms-unseal-${var.cluster_name}*"]
  }
}


data "aws_route53_zone" "root_zone" {
  name         = var.baseDomain
  private_zone = false
}


data "template_file" "minio" {
  template = file("./scripts/userdata.tpl")

  vars = {
    minio_domain        = "platform-minio-${var.cluster_name}.${data.aws_route53_zone.root_zone.name}"
    minio_root_password = random_password.password.result
    minio_root_user     = var.minio_root_user
    minio_url           = var.minio_url
    minio_volume_path   = var.minio_volume_path
    bucket_name         = var.backup_bucket_name
    aws_region          = var.aws_region
  }
}

data "template_file" "format_ssh" {
  template = "connect to host with following command: ssh ubuntu@$${admin} -i private_minio.key"

  vars = {
    admin = aws_eip.minio_ip.public_ip
  }
}
