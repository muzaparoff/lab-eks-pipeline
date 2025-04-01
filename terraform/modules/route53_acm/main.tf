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

# Use imported certificate with validation
resource "aws_acm_certificate" "cert" {
  # Use local-exec to validate base64 strings before using them
  provisioner "local-exec" {
    command = <<-EOT
      echo "${var.certificate_body}" | base64 -d > /dev/null || exit 1
      echo "${var.certificate_key}" | base64 -d > /dev/null || exit 1
    EOT
  }

  certificate_body = sensitive(trimspace(var.certificate_body))
  private_key     = sensitive(trimspace(var.certificate_key))
  
  tags = {
    Name = var.cert_domain
  }

  lifecycle {
    create_before_destroy = true
    # Add precondition to validate variables are not empty
    precondition {
      condition     = var.certificate_body != "" && var.certificate_key != ""
      error_message = "Certificate body and private key must not be empty"
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