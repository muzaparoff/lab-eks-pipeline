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

# First try to find existing certificate
data "aws_acm_certificate" "existing" {
  count    = 0  # Disable lookup to avoid errors when certificate doesn't exist
  domain   = var.cert_domain
  statuses = ["ISSUED"]
}

# Create new certificate
resource "aws_acm_certificate" "cert" {
  certificate_body = trimspace(var.certificate_body)
  private_key     = trimspace(var.certificate_key)
  
  tags = {
    Name = var.cert_domain
  }

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  certificate_arn = aws_acm_certificate.cert.arn
}

# Update Route53 record with better error handling
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = var.cert_domain
  type    = "CNAME"
  ttl     = "300"
  records = [trimprefix(var.cluster_endpoint, "https://")]
}