locals {
  cf_origin_id = "S3-${var.domain_name}"
}

resource "aws_cloudfront_origin_access_identity" "site" {
  comment = "CF access identity for hosting ${var.domain_name}"
}

resource "aws_cloudfront_distribution" "site" {
  origin {
    domain_name = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id   = local.cf_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.site.cloudfront_access_identity_path
    }
    # Not needed because we are accessing the bucket directly now and not via a website config
    # custom_origin_config {
    #   http_port              = 80
    #   https_port             = 443
    #   origin_protocol_policy = "http-only"
    #   # feel like I should remove TLSv1...pi
    #   origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    # }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = ["${var.domain_name}"]

  #   aliases = ["www.${var.domain_name}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.cf_origin_id

    forwarded_values {
      query_string = true
      cookies {
        # I need to change this to whitelist... in the case auth stuff is ever in the cookies...
        forward = "all"
        # whitelisted_names = [  ]
      }
      # Not needed because we are accessing the bucket directly now and not via a website config
      # headers = ["*"]
      headers = []
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 600
    max_ttl                = 3600
  }

  logging_config {
    include_cookies = true
    bucket          = "${aws_s3_bucket.logs.id}.s3.amazonaws.com"
    prefix          = var.domain_name
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.site.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1"
  }
}
