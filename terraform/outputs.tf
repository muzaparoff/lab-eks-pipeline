output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "app_domain" {
  value = module.route53_acm.app_domain
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}
