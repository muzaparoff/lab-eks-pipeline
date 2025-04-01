output "certificate_arn" {
  value = local.certificate_arn
}

output "app_domain" {
  value = aws_route53_record.app.name
}