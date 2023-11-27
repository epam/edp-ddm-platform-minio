resource "aws_instance" "minio" {

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.minio_ec2_instance_type
  subnet_id     = data.aws_subnet.public_subnet.id
  key_name      = aws_key_pair.main.key_name
  monitoring    = "false"

  vpc_security_group_ids = [
    aws_security_group.minio.id,
  ]

  ebs_optimized = false

  tags = merge(local.tags, {
    "Name" = "platform-minio-${var.cluster_name}"
  })

  user_data = data.template_file.minio.rendered

}

resource "aws_ebs_volume" "minio_ebs" {
  availability_zone = var.aws_zone
  size              = var.minio_ebs_volume_size

  tags = merge(local.tags, {
    "Name" = "platform-minio-volume-${var.cluster_name}"
  })
}

resource "aws_volume_attachment" "minio_ebs" {
  device_name                    = var.minio_volume_path
  volume_id                      = aws_ebs_volume.minio_ebs.id
  instance_id                    = aws_instance.minio.id
  stop_instance_before_detaching = true
}

resource "aws_security_group" "minio" {
  name        = "minio-${var.cluster_name}"
  description = "minio access"
  vpc_id      = data.aws_vpc.vpc.id

  tags = merge(local.tags, {
    "Name" = "platform-minio-${var.cluster_name}-sg"
  })

  ingress {
    from_port   = 9001
    to_port     = 9001
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.external_ip.body)}/32"]
  }

  ingress {
    from_port   = 9001
    to_port     = 9001
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_nat_gateway.cluster_ip.public_ip}/32"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_nat_gateway.cluster_ip.public_ip}/32"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.external_ip.body)}/32"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "null_resource" "minio_init" {
  provisioner "local-exec" {
    command     = var.wait_for_cluster_cmd
    interpreter = var.wait_for_cluster_interpreter
    environment = {
      ENDPOINT = "http://${aws_eip.minio_ip.public_ip}:9001"
    }
  }
  depends_on = [aws_instance.minio]
}
