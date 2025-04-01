variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR for the new VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for a public subnet for NAT Gateway"
  type        = string
  default     = "10.10.1.0/24"
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets"
  type        = list(string)
  default     = ["10.10.2.0/24", "10.10.3.0/24"]
}

variable "eks_version" {
  description = "EKS Cluster version"
  type        = string
  default     = "1.30"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "lab-eks-cluster"
}

variable "db_username" {
  description = "Username for the RDS database"
  type        = string
  default     = "dbadmin"  # Changed from "admin" to avoid reserved word
}

variable "db_password" {
  description = "Password for the RDS database. Provide via TF_VAR_db_password environment variable."
  type        = string
  sensitive   = true
}

variable "db_engine" {
  description = "Database engine (postgres or mysql)"
  type        = string
  default     = "postgres"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "labapp"
}

variable "domain_name" {
  description = "Domain name for Route53 hosted zone"
  type        = string
  default     = "labinternal.example.com"
}

variable "cert_domain" {
  description = "Domain for which the ACM certificate is created"
  type        = string
  default     = "app.labinternal.example.com"
}

variable "repository_name" {
  description = "Name for the CodeCommit repository"
  type        = string
  default     = "lab-eks-pipeline-repo"
}

variable "eks_namespace" {
  description = "Kubernetes namespace for app deployment"
  type        = string
  default     = "lab-app"
}

variable "app_version" {
  description = "Application version"
  type        = string
  default     = "1.0.0"
}

variable "ecr_image_tag_mutability" {
  description = "ECR image tag mutability"
  type        = string
  default     = "MUTABLE"
}

variable "enable_ecr_scan_on_push" {
  description = "Enable ECR scan on push"
  type        = bool
  default     = true
}

variable "certificate_body" {
  description = "Base64 encoded certificate body"
  type        = string
  sensitive   = true
}

variable "certificate_key" {
  description = "Base64 encoded certificate private key"
  type        = string
  sensitive   = true
}