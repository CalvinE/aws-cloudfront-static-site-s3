output "domain_name" {
  value = var.domain_name
}

output "bucket_arn" {
  value = aws_s3_bucket.site.arn
}

output "bucket_name" {
  value = aws_s3_bucket.site.id
}

output "log_bucket_arn" {
  value = aws_s3_bucket.logs.arn
}

output "log_bucket_name" {
  value = aws_s3_bucket.logs.id
}

output "site_url" {
  value = "https://${var.domain_name}"
}

output "deployer_role_arn" {
  value = aws_iam_role.deploy.arn
}
