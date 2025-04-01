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
}

variable "certificate_key" {
  description = "Base64 encoded certificate private key"
  type        = string
}