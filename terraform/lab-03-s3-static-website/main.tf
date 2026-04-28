resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  bucket_name = "${var.suffix}-static-${random_id.suffix.hex}"

  index_html = templatefile("${path.module}/web/index.html.tpl", {
    full_name   = var.full_name
    roll_number = var.roll_number
    institution = var.institution
    faculty     = var.faculty
    region      = var.region
  })

  error_html = templatefile("${path.module}/web/error.html.tpl", {
    full_name    = var.full_name
    subject_name = var.subject_name
  })
}

resource "aws_s3_bucket" "site" {
  bucket        = local.bucket_name
  force_destroy = true

  tags = {
    Name = "${var.suffix}-static-site"
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "site" {
  depends_on = [aws_s3_bucket_public_access_block.site]
  bucket     = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.site.arn}/*"
      }
    ]
  })
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  content      = local.index_html
  content_type = "text/html"
  etag         = md5(local.index_html)
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.site.id
  key          = "error.html"
  content      = local.error_html
  content_type = "text/html"
  etag         = md5(local.error_html)
}
