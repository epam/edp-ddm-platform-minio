resource "aws_eip" "minio_ip" {
  vpc = true
  tags = merge(local.tags, {
    "Name" = "platform-minio-ip-${var.cluster_name}"
  })
}

resource "aws_eip_association" "minio_public" {
  instance_id   = aws_instance.minio.id
  allocation_id = aws_eip.minio_ip.id
}