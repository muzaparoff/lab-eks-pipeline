output "certificate_arn" {
  value = data.aws_acm_certificate.existing.arn
}

output "app_domain" {
  value = aws_route53_record.app.name
}