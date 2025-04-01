output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_ca_certificate" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

# For Route53/ACM module, provide VPC info instead of ALB
output "vpc_id" {
  value = var.vpc_id
}

output "backend_security_group_id" {
  value = aws_security_group.node_group.id
  description = "Security group ID for EKS node group (used by backend pods)"
}