# Route 53のzoneを取得する
data "aws_route53_zone" "main" {
  name         = "parking-checker.com"
  private_zone = false
}

# ACMが要求してきた検証用CNAMEをDNSに置く
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

# parking-checker.comのAレコードを作成
resource "aws_route53_record" "apex" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "parking-checker.com"
  type    = "A"

  alias {
    name = aws_alb.main.dns_name # ALBのDNS名
    zone_id = aws_alb.main.zone_id # ALBのzone ID
    evaluate_target_health = true # ALBの状態を評価する
  }
}

# 静的コンテンツ用ACM証明書のDNS検証レコード
resource "aws_route53_record" "assets_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.assets.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

# assets.parking-checker.comのAレコードを作成
resource "aws_route53_record" "assets_apex" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "assets.parking-checker.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}