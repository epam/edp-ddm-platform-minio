resource "aws_eip" "minio_ip" {
  vpc  = true
  tags = local.tags
}

resource "aws_eip_association" "minio_public" {
  instance_id   = aws_instance.minio.id
  allocation_id = aws_eip.minio_ip.id
}