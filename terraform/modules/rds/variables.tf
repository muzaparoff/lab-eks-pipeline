variable "vpc_id" {
  description = "VPC ID for RDS"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for RDS"
  type        = list(string)
}

variable "db_username" {
  description = "RDS DB username"
  default     = "admin"
  sensitive   = true
  type        = string
}

variable "db_password" {
  description = "RDS DB password"
  default     = "P@ssw0rd123"
  type        = string
  sensitive   = true
}

variable "db_engine" {
  description = "Database engine (postgres or mysql)"
  type        = string
}

variable "db_name" {
  description = "Database name"
  default = "my-app-db"
  type        = string
}