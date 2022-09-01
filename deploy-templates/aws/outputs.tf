output "minio_cred" {
  sensitive = true
  value     = random_password.password.result
}

output "minio_username" {
  value = var.minio_root_user
}

output "minio_password" {
  sensitive = true
  value     = random_password.password.result
}

output "minio_endpoint" {
  value = "https://${aws_route53_record.minio.name}"
}