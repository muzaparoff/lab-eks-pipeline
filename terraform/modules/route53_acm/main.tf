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

# First check for existing certificate
data "aws_acm_certificate" "existing" {
  domain   = var.cert_domain
  statuses = ["ISSUED"]

  lifecycle {
    postcondition {
      condition     = self.arn != null
      error_message = "No valid certificate found for domain ${var.cert_domain}"
    }
  }
}

# Only create new certificate if data lookup fails
resource "aws_acm_certificate" "cert" {
  count = data.aws_acm_certificate.existing.arn == null ? 1 : 0
  
  certificate_body = trimspace(var.certificate_body)
  private_key     = trimspace(var.certificate_key)
  
  tags = {
    Name = var.cert_domain
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      certificate_body,
      private_key
    ]
  }
}

locals {
  certificate_arn = try(data.aws_acm_certificate.existing.arn, try(aws_acm_certificate.cert[0].arn, null))
}

# Update Route53 record with better error handling
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = var.cert_domain
  type    = "CNAME"
  ttl     = "300"
  records = [trimprefix(var.cluster_endpoint, "https://")]
}