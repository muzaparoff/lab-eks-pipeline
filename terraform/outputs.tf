output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "app_domain" {
  value = module.route53_acm.app_domain
}

output "ecr_frontend_repository_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "ecr_backend_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}
