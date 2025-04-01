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

resource "aws_acm_certificate" "cert" {
  certificate_body  = base64decode(var.certificate_body)
  private_key      = base64decode(var.private_key)
  
  tags = {
    Name = var.cert_domain
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Look for existing certificate with error handling
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

# Update Route53 record with better error handling
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = var.cert_domain
  type    = "CNAME"
  ttl     = "300"
  records = [trimprefix(var.cluster_endpoint, "https://")]
}