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

resource "aws_iam_role_policy_attachment" "eks_cluster_admin" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_security_group" "eks_cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTPS API server access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {
    description = "Allow worker nodes communication"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    self        = true
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

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_security_group" "node_group" {
  name        = "${var.cluster_name}-node-group-sg-${random_id.suffix.hex}"
  description = "Security group for EKS node group"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow inter-node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description = "Allow frontend traffic"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {
    description = "Allow backend traffic"
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-node-group-sg-${random_id.suffix.hex}"
    Cluster = var.cluster_name
  }

  lifecycle {
    create_before_destroy = true
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

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy
  ]

  timeouts {
    delete = "30m"
  }
}

// Create managed node group
resource "aws_iam_role" "node_group" {
  name = "${var.cluster_name}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_group_policies" {
  for_each = {
    AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    AmazonEKS_CNI_Policy              = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }

  policy_arn = each.value
  role       = aws_iam_role.node_group.name
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_subnets

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_group_policies
  ]
}

resource "aws_launch_template" "eks_nodes" {
  name_prefix = "${var.cluster_name}-node-"
  
  vpc_security_group_ids = [aws_security_group.node_group.id]
  
  // ...rest of launch template config...
}

// Create OIDC provider (required for IRSA)
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.this.name
}

// Create new OIDC provider
resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  url             = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0eabb0c4f"]
}

locals {
  oidc_provider_arn = aws_iam_openid_connect_provider.oidc.arn
}

// Create IAM role for ALB controller
resource "aws_iam_role" "alb_controller" {
  name = "${var.cluster_name}-alb-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.oidc.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

// Add IAM policy for ALB controller
resource "aws_iam_role_policy" "alb_controller" {
  name = "${var.cluster_name}-alb-controller-policy"
  role = aws_iam_role.alb_controller.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeSecurityGroups",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DescribeInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:CreateTags",
          "elasticloadbalancing:*",
          "iam:CreateServiceLinkedRole"
        ],
        Resource = "*"
      }
    ]
  })
}

// Modify wait_for_cluster to use AWS CLI for validation
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
      for i in {1..30}; do
        if aws eks get-token --cluster-name ${aws_eks_cluster.this.name} > /dev/null 2>&1; then
          echo "Cluster is accessible"
          exit 0
        fi
        echo "Waiting for cluster to be accessible... attempt $i"
        sleep 10
      done
      echo "Timeout waiting for cluster to be accessible"
      exit 1
    EOT
  }
}

data "aws_region" "current" {}

// Update aws-auth ConfigMap
resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.node_group.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      },
      {
        rolearn  = aws_iam_role.eks_cluster_role.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])
    mapUsers = yamlencode([
      {
        userarn  = data.aws_caller_identity.current.arn
        username = "admin"
        groups   = ["system:masters"]
      }
    ])
  }

  force = true

  depends_on = [aws_eks_cluster.this, null_resource.wait_for_cluster]
}

data "aws_caller_identity" "current" {}

// Add RBAC role for admin
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

  depends_on = [kubernetes_config_map_v1_data.aws_auth]
}

// Add cluster admin binding
resource "kubernetes_cluster_role_binding" "cluster_admin" {
  metadata {
    name = "terraform-admin"
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

  depends_on = [kubernetes_config_map_v1_data.aws_auth]
}

// Install ALB controller with increased timeout and better error handling
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.4.4"

  values = [
    <<-EOT
    clusterName: ${var.cluster_name}
    serviceAccount:
      create: true
      annotations:
        eks.amazonaws.com/role-arn: ${aws_iam_role.alb_controller.arn}
    region: ${data.aws_region.current.name}
    vpcId: ${var.vpc_id}
    ingressClass: alb
    EOT
  ]

  timeout = 300
  wait    = true
  atomic  = false

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.this,
    kubernetes_config_map_v1_data.aws_auth
  ]
}

// Clean up and install ArgoCD
resource "null_resource" "cleanup_argocd" {
  triggers = {
    cluster_endpoint = aws_eks_cluster.this.endpoint
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Cleaning up existing ArgoCD resources..."
      # Remove finalizers first to ensure clean deletion
      kubectl patch application -n argocd --type json --patch='[ { "op": "remove", "path": "/metadata/finalizers" } ]' -A || true
      
      # Delete resources in correct order
      kubectl delete application -n argocd --all --timeout=60s || true
      kubectl delete appproject -n argocd --all --timeout=60s || true
      kubectl delete -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --timeout=60s || true
      kubectl delete namespace argocd --timeout=60s || true
      
      # Wait for namespace deletion
      for i in {1..30}; do
        if ! kubectl get namespace argocd >/dev/null 2>&1; then
          break
        fi
        echo "Waiting for argocd namespace deletion... attempt $i"
        sleep 10
      done
    EOT
  }

  depends_on = [aws_eks_cluster.this]
}

// ArgoCD Installation
resource "helm_release" "argocd" {
  name             = "argocd-${random_id.suffix.hex}"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.46.7"
  
  force_update     = true
  cleanup_on_fail  = true
  atomic          = true
  timeout         = 900

  values = [
    <<-EOT
    server:
      extraArgs:
        - --insecure
      service:
        annotations: {}
    configs:
      secret:
        createSecret: true
    dex:
      enabled: false
    notifications:
      enabled: false
    applicationSet:
      enabled: true
    global:
      deploymentAnnotations:
        meta.helm.sh/release-name: "argocd-${random_id.suffix.hex}"
    EOT
  ]

  set {
    name  = "crds.install"
    value = "true"
  }

  depends_on = [
    aws_eks_cluster.this,
    kubernetes_config_map_v1_data.aws_auth,
    null_resource.cleanup_argocd
  ]

  lifecycle {
    create_before_destroy = true
  }
}