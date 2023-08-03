data "aws_route53_zone" "site" {
  name         = var.hosted_zone_name
  private_zone = false
}

resource "aws_route53_record" "site" {
  zone_id = data.aws_route53_zone.site.id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}
