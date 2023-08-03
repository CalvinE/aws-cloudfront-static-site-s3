resource "aws_s3_bucket" "site" {
  # TODO: over thinging here, but could this cause a collision? Should we use bucket_prefix?
  bucket = var.domain_name
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "site" {
  bucket = aws_s3_bucket.site.id
  acl    = "public-read"

  depends_on = [
    aws_s3_bucket_public_access_block.site,
    aws_s3_bucket_ownership_controls.site,
  ]
}

data "aws_iam_policy_document" "site_policy" {
  statement {
    sid    = "PublicReadGetObjectCFPrincipal"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.site.id}"]
    }
  }
  statement {
    sid    = "PublicReadGetObjectCFOAI"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.site.iam_arn]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
  }
}


# Not needed because we are accessing the bucket directly now and not via a website config
# {
# 	"Sid": "PublicReadGetObject",
# 	"Effect": "Allow",
# 	"Principal": {
# 		"Service": "cloudfront.amazonaws.com"
# 	},
# 	"Action": "s3:GetObject",
# 	"Resource": "arn:aws:s3:::blog.cechols.com/*",
# 	"Condition": {
# 		"StringEquals": {
# 			"AWS:SourceArn": "arn:aws:cloudfront::290491194943:distribution/ET6FIANIVYUAT"
# 		}
# 	}
# }

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site_policy.json

  depends_on = [
    aws_s3_bucket_public_access_block.site,
    aws_s3_bucket_ownership_controls.site,
  ]
}


# Not needed because we are accessing the bucket directly now and not via a website config
# resource "aws_s3_bucket_cors_configuration" "site" {
#   bucket = aws_s3_bucket.site.id
#   // Will want more rules as more functionality is developed?
#   cors_rule {
#     allowed_methods = ["GET"]
#     allowed_origins = ["http://${var.domain_name}"]
#   }
# }


# Not needed because we are accessing the bucket directly now and not via a website config
# resource "aws_s3_bucket_website_configuration" "site" {
#   bucket = aws_s3_bucket.site.id
#   index_document {
#     suffix = "index.html"
#   }
# }


### Site logs bucket

resource "aws_s3_bucket" "logs" {
  # TODO: over thinging here, but could this cause a collision? Should we use bucket_prefix?
  bucket = "${var.domain_name}-logs"
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  bucket = aws_s3_bucket.logs.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.logs]
}

# data "aws_iam_policy_document" "logs" {
#   statement {
#     principals {
#       type = "AWS"
#       identifiers = [ aws_cloudfront_distribution.site.arn ]
#     }
#     effect = "Allow"
#     actions = [ "s3:PutObject" ]
#     resources = [ "${aws_s3_bucket.logs.arn}/*" ]
#   }
# }

# resource "aws_s3_bucket_policy" "logs" {
#   bucket = aws_s3_bucket.logs.id
#   policy = data.aws_iam_policy_document.logs.json

#     depends_on = [
#     # aws_s3_bucket_public_access_block.logs,
#     aws_s3_bucket_ownership_controls.logs,
#   ]
# }
