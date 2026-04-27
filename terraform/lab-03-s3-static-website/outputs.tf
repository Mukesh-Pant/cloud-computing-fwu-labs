output "bucket_name" {
  value       = aws_s3_bucket.site.id
  description = "Name of the S3 bucket"
}

output "website_endpoint" {
  value       = aws_s3_bucket_website_configuration.site.website_endpoint
  description = "S3 static website endpoint"
}

output "website_url" {
  value       = "http://${aws_s3_bucket_website_configuration.site.website_endpoint}"
  description = "Open this URL in a browser to view the static site"
}
