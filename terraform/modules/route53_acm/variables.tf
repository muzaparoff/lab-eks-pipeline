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

variable "alb_dns_name" {
  description = "ALB DNS name for Route53 alias"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB zone ID for Route53 alias"
  type        = string
}

variable "certificate_body" {
  description = "PEM formatted certificate body"
  type        = string
  default     = ""
}

variable "certificate_private_key" {
  description = "PEM formatted private key"
  type        = string
  default     = ""
}

variable "certificate_chain" {
  description = "PEM formatted certificate chain"
  type        = string
  default     = ""
}