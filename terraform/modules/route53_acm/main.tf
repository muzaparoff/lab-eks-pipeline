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

# Use imported certificate
resource "aws_acm_certificate" "cert" {
  certificate_body  = base64decode(var.certificate_body)
  private_key      = base64decode(var.certificate_key)
  
  tags = {
    Name = var.cert_domain
  }

  lifecycle {
    create_before_destroy = true
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