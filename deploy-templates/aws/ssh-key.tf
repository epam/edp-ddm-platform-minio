resource "tls_private_key" "main" {
  algorithm = "RSA"
}

resource "null_resource" "main" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.main.private_key_pem}\" > private_minio.key"
  }

  provisioner "local-exec" {
    command = "chmod 600 private_minio.key"
  }
}

resource "aws_key_pair" "main" {
  key_name   = "minio-ssh-key-${var.cluster_name}"
  public_key = tls_private_key.main.public_key_openssh
  tags = merge(local.tags, {
    "Name" = "platform-minio-${var.cluster_name}"
  })
}
