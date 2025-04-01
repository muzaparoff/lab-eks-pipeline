variable "domain_name" {
  description = "Domain name for Route53 private hosted zone"
  type        = string
}

variable "cert_domain" {
  description = "Domain name for SSL certificate"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for private hosted zone"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "certificate_body" {
  description = "Base64 encoded certificate body"
  type        = string
  sensitive   = true
  
  validation {
    condition     = can(base64decode(var.certificate_body))
    error_message = "Certificate body must be valid base64"
  }
}

variable "certificate_key" {
  description = "Base64 encoded certificate private key"
  type        = string
  sensitive   = true
  
  validation {
    condition     = can(base64decode(var.certificate_key))
    error_message = "Certificate key must be valid base64"
  }
}