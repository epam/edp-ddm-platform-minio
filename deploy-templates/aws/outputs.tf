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

output "minio_elastic_ip" {
  value = aws_eip.minio_ip.public_ip
}
