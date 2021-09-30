
resource "aws_route53_record" "minio" {
  zone_id = data.aws_route53_zone.root_zone.zone_id
  name    = "platform-minio-${var.cluster_name}.${data.aws_route53_zone.root_zone.name}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.minio_ip.public_ip]
}