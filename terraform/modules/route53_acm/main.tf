# Create a private hosted zone. For the purpose of this lab we assume the VPC has CIDR 10.10.0.0/16.
resource "aws_route53_zone" "internal" {
  name = var.domain_name
  
  vpc {
    vpc_id = var.vpc_id
  }

  tags = {
    Name = "${var.domain_name}-private-zone"
  }
}

# Store certificate content in SSM Parameter Store
resource "aws_ssm_parameter" "certificate" {
  name  = "/${var.cert_domain}/certificate"
  type  = "SecureString"
  value = base64encode(local.certificate_content)
}

resource "aws_ssm_parameter" "private_key" {
  name  = "/${var.cert_domain}/private-key"
  type  = "SecureString"
  value = base64encode(local.private_key_content)
}

locals {
  certificate_content = <<-EOT
    ${base64decode(data.external.generate_cert.result.certificate)}
  EOT
  private_key_content = <<-EOT
    ${base64decode(data.external.generate_cert.result.private_key)}
  EOT
}

# Generate certificate using external data source
data "external" "generate_cert" {
  program = ["bash", "${path.module}/generate_cert.sh", var.cert_domain]
}

# Create local directory for certificates
resource "null_resource" "cert_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/certificates"
  }
}

# Generate certificate only if it doesn't exist
resource "null_resource" "generate_certificate" {
  triggers = {
    cert_file_exists = fileexists("${path.module}/certificates/certificate.crt") ? "exists" : timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      if [ ! -f "${path.module}/certificates/certificate.crt" ]; then
        mkdir -p ${path.module}/certificates
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
          -keyout ${path.module}/certificates/private.key \
          -out ${path.module}/certificates/certificate.crt \
          -subj "/CN=${var.cert_domain}"
      fi
    EOT
  }
}

# Import certificate into ACM
resource "aws_acm_certificate" "cert" {
  certificate_body  = local.certificate_content
  private_key      = local.private_key_content
  
  tags = {
    Name = var.cert_domain
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Add Route53 record
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = var.cert_domain
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id               = var.alb_zone_id
    evaluate_target_health = true
  }
}