output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "alb_dns_name" {
  value = data.kubernetes_service.alb_controller.status.0.load_balancer.0.ingress.0.hostname
}

output "alb_zone_id" {
  value = data.aws_lb.alb.zone_id
}

output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_ca_certificate" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}