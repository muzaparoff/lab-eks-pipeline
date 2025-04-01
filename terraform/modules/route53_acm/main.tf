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

# Look for existing certificate
data "aws_acm_certificate" "existing" {
  domain   = var.cert_domain
  statuses = ["ISSUED", "PENDING_VALIDATION"]
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
  count = data.aws_acm_certificate.existing.arn == null ? 1 : 0

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

# Import certificate into ACM only if it doesn't exist
resource "aws_acm_certificate" "cert" {
  count = data.aws_acm_certificate.existing.arn == null ? 1 : 0

  certificate_body  = local.certificate_content
  private_key      = local.private_key_content
  
  tags = {
    Name = var.cert_domain
  }

  lifecycle {
    create_before_destroy = true
  }
}

// Update Route53 record to use CNAME instead of ALB alias
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = var.cert_domain
  type    = "CNAME"
  ttl     = "300"
  records = [trimprefix(var.cluster_endpoint, "https://")]

  depends_on = [
    aws_acm_certificate.cert,
    data.aws_acm_certificate.existing
  ]
}

# Update outputs to use either existing or new certificate
locals {
  certificate_arn = data.aws_acm_certificate.existing.arn != null ? data.aws_acm_certificate.existing.arn : aws_acm_certificate.cert[0].arn
}

output "certificate_arn" {
  value = local.certificate_arn
}