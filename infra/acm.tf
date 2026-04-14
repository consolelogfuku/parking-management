# ドメイン用ACM証明書を作成する（ap-northeast-1）
resource "aws_acm_certificate" "main" {
  domain_name = "parking-checker.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "parking-management-cert"
  }
}

# ACM証明書を検証する
resource "aws_acm_certificate_validation" "main" {
  certificate_arn = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# ドメイン用ACM証明書を作成する（us-east-1）
resource "aws_acm_certificate" "main_us_east_1" {
  provider          = aws.us_east_1
  domain_name       = "parking-checker.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "parking-checker-cloudfront-cert"
  }
}

# CloudFront用ACM証明書を検証する
resource "aws_acm_certificate_validation" "main_us_east_1" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.main_us_east_1.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn] # ドメインの検証用CNAMEをDNSに置く
}

# 静的コンテンツ用ACM証明書を作成する
resource "aws_acm_certificate" "assets" {
  provider          = aws.us_east_1 # CloudFrontはus-east-1で動作するため、us-east-1プロバイダを使用する
  domain_name       = "assets.parking-checker.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "parking-management-assets-cert"
  }
}

# 静的コンテンツ用ACM証明書を検証する
resource "aws_acm_certificate_validation" "assets" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.assets.arn
  validation_record_fqdns = [for record in aws_route53_record.assets_cert_validation :
record.fqdn]
}