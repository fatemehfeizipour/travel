resource "aws_cloudfront_origin_access_control" "website_oac" {
  name                              = "travelease-website-oac"
  description                       = "Lets CloudFront read the private website bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.host_bucket.bucket_regional_domain_name
    origin_id                = "website-bucket"
    origin_access_control_id = aws_cloudfront_origin_access_control.website_oac.id
  }

  default_cache_behavior {
    target_origin_id       = "website-bucket"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    project = "travelease-contact-rebuild"
  }
}