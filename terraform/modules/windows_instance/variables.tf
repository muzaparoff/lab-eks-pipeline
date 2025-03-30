variable "vpc_id" {
  description = "VPC ID for the Windows instance"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs where the Windows instance will be placed"
  type        = list(string)
}