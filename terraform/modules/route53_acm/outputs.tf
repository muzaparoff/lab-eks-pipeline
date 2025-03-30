output "certificate_arn" {
  value = aws_acm_certificate.cert.arn
}

output "app_domain" {
  value = aws_route53_record.app.name
}