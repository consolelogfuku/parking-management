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