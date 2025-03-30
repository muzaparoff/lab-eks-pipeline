resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Create cluster security group
resource "aws_security_group" "eks_cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow API server access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]  # VPC CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-cluster-sg"
  }
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids              = var.private_subnets
    endpoint_private_access = true
    endpoint_public_access  = true  # Temporarily enable for initial setup
    security_group_ids     = [aws_security_group.eks_cluster.id]
  }

  version = var.cluster_version

  tags = {
    Name = var.cluster_name
  }
}

resource "aws_iam_role" "eks_fargate_role" {
  name = "${var.cluster_name}-fargate-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_fargate_AmazonEKSFargatePodExecutionRolePolicy" {
  role       = aws_iam_role.eks_fargate_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

resource "aws_eks_fargate_profile" "default" {
  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = "${var.cluster_name}-fargate-profile"
  pod_execution_role_arn = aws_iam_role.eks_fargate_role.arn
  subnet_ids             = var.private_subnets

  selector {
    namespace = "default"
  }

  selector {
    namespace = "lab-app"
  }
}

# Create OIDC provider (required for IRSA)
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.this.name
}

# Check for existing OIDC provider
data "aws_iam_openid_connect_provider" "existing" {
  count = 1
  url   = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc" {
  count = data.aws_iam_openid_connect_provider.existing[0] == null ? 1 : 0
  
  client_id_list  = ["sts.amazonaws.com"]
  url             = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0eabb0c4f"]
}

locals {
  oidc_provider_arn = data.aws_iam_openid_connect_provider.existing[0] != null ? data.aws_iam_openid_connect_provider.existing[0].arn : aws_iam_openid_connect_provider.oidc[0].arn
}

# Create IAM role for ALB controller
resource "aws_iam_role" "alb_controller" {
  name = "${var.cluster_name}-alb-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = local.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

# Modify wait_for_cluster to use AWS CLI for validation
resource "null_resource" "wait_for_cluster" {
  depends_on = [aws_eks_cluster.this]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for EKS cluster to be active..."
      aws eks wait cluster-active \
        --name ${aws_eks_cluster.this.name} \
        --region ${data.aws_region.current.name}
      
      echo "Updating kubeconfig..."
      aws eks update-kubeconfig \
        --name ${aws_eks_cluster.this.name} \
        --region ${data.aws_region.current.name}
      
      echo "Testing cluster connectivity..."
      /usr/local/bin/kubectl get nodes --timeout=5m
    EOT
  }
}

data "aws_region" "current" {}

# Create aws-auth ConfigMap
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.eks_fargate_role.arn
        username = "system:node:{{SessionName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      },
      {
        rolearn  = data.aws_caller_identity.current.arn
        username = "admin"
        groups   = ["system:masters"]
      }
    ])
  }

  depends_on = [null_resource.wait_for_cluster]
}

data "aws_caller_identity" "current" {}

# Add RBAC role for admin
resource "kubernetes_cluster_role_binding" "admin" {
  metadata {
    name = "eks-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "User"
    name      = "admin"
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [kubernetes_config_map.aws_auth]
}

# Install ALB controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.this.name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb_controller.arn
  }

  timeout = 600  # 10 minutes
  wait    = true

  depends_on = [
    aws_eks_cluster.this,
    null_resource.wait_for_cluster
  ]
}

# Wait for ALB controller deployment
resource "time_sleep" "wait_for_alb" {
  depends_on = [helm_release.aws_load_balancer_controller]
  create_duration = "30s"
}

# Get ALB details
data "kubernetes_service" "alb_controller" {
  depends_on = [time_sleep.wait_for_alb]
  metadata {
    name = "aws-load-balancer-controller"
    namespace = "kube-system"
  }
}

data "aws_lb" "alb" {
  depends_on = [time_sleep.wait_for_alb]
  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/service-name" = "kube-system/aws-load-balancer-controller"
  }
}