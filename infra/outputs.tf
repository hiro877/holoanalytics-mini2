output "s3_bucket_name" { value = aws_s3_bucket.raw.bucket }
output "mysql_endpoint" { value = aws_db_instance.mysql.endpoint }
output "mysql_username" { value = var.db_username }
output "mysql_password" {
  value     = var.db_password
  sensitive = true
}
