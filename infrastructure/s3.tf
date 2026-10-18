resource "aws_s3_bucket" "host_bucket" {
  bucket = "travelease-host-bucket-name"
  tags = {
    project = "travelease-contact-rebuild"
  }
}

# resource "aws_s3_bucket_website_configuration" "bucket_configuration_id" {
#     bucket = aws_s3_bucket.host_bucket_id.id
#     index_document {
#         suffix = "index.html"
#         }
#     error_document {
#         key = "error.html"
#         }
#     }
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.host_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.host_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontRead"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.host_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website.arn
          }
        }
      },
    ]
  })
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.host_bucket.id
  key          = "index.html"
  source       = "${path.module}/../frontend/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/../frontend/index.html")
}

resource "aws_s3_object" "style_css" {
  bucket       = aws_s3_bucket.host_bucket.id
  key          = "style.css"
  source       = "${path.module}/../frontend/style.css"
  content_type = "text/css"
  etag         = filemd5("${path.module}/../frontend/style.css")
}

resource "aws_s3_object" "script_js" {
  bucket       = aws_s3_bucket.host_bucket.id
  key          = "script.js"
  source       = "${path.module}/../frontend/script.js"
  content_type = "text/javascript"
  etag         = filemd5("${path.module}/../frontend/script.js")
}