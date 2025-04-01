# Lab EKS Pipeline

This repository contains a fully automated solution for deploying an AWS environment with EKS, a Python front/back application deployed via Helm and ArgoCD, internal ALB with SSL termination, a private RDS database, GitHub Actions for CI/CD, and monitoring. All resources are provisioned via Terraform in the `us-east-1` region.

## Repository Structure

- **terraform/**: Terraform code to provision AWS resources
- **helm/lab-app/**: Helm chart to deploy the application
- **app/**: Python application code
  - **frontend/**: Flask frontend service
  - **backend/**: Flask backend service with RDS connectivity
- **scripts/**: Helper scripts
  - **generate_password.sh**: Generates secure RDS password
  - **generate_cert.sh**: Generates self-signed certificates
  - **install_argocd.sh**: Installs and configures ArgoCD
- **k8s/**: Kubernetes manifests including ArgoCD configuration
- **docker/**: Docker-related files for local development

## Pre-requisites

- AWS CLI configured with necessary permissions
- Docker Desktop
- OpenSSL (for certificate generation)
- DockerHub account and access token
- GitHub account with repository access

## Setup Instructions

### 1. Initial Setup

Generate and configure the self-signed certificate:
```bash
# Generate certificate with proper extensions
./scripts/generate_and_upload_cert.sh app.labinternal.example.com

# The script will output the base64-encoded values to add to GitHub secrets:
# - GH_CERT_BODY: The certificate content
# - GH_CERT_KEY: The private key content
```

Add the certificate values to GitHub repository secrets. The generated certificate includes:
- Subject Alternative Names (SAN)
- Proper key usage extensions
- 365-day validity
- 2048-bit RSA key

# Generate database password
source scripts/generate_password.sh

# Build Terraform runner container
docker build -t terraform-runner -f docker/Terraform.dockerfile .

# Create terraform alias
alias tf='docker run --rm -it \
  -v ~/.aws:/root/.aws:ro \
  -v $(pwd):/workspace \
  -w /workspace \
  -e AWS_PROFILE=lab-admin \
  -e TF_VAR_db_password=$TF_VAR_db_password \
  -e TF_VAR_certificate_body=$(cat ../certificates/certificate.crt | base64) \
  -e TF_VAR_certificate_key=$(cat ../certificates/private.key | base64) \
  muzaparoff/terraform-runner:latest'

### 2. Set Up GitHub Repository

1. Create a new GitHub repository
2. Add repository secrets:
```bash
# Get ECR URLs and GitHub Actions credentials
cd terraform
ECR_FRONTEND=$(tf output -raw ecr_frontend_repository_url)
ECR_BACKEND=$(tf output -raw ecr_backend_repository_url)
AWS_ACCESS_KEY=$(tf output -raw github_actions_key_id)
AWS_SECRET_KEY=$(tf output -raw github_actions_secret)

# Add these as GitHub repository secrets:
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- ECR_FRONTEND_URL
- ECR_BACKEND_URL
- DB_PASSWORD
- GH_CERT_BODY
- GH_CERT_KEY
- DOCKERHUB_USERNAME
- DOCKERHUB_TOKEN
```

3. Push code to GitHub:
```bash
git remote add origin https://github.com/yourusername/lab-eks-pipeline.git
git push -u origin main
```

### 3. Provision Infrastructure
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This creates:
* VPC with private subnets and NAT Gateway
* EKS v1.30 cluster with managed node groups
* RDS PostgreSQL in private subnets
* Route53 private hosted zone
* Self-signed certificate in ACM
* ArgoCD for GitOps deployments
* AWS Load Balancer Controller
* Prometheus/Grafana monitoring stack

### 4. Configure ArgoCD

Update ArgoCD application with your GitHub repository:
```bash
# Edit k8s/argocd-app.yaml to point to your repository
repoURL: https://github.com/yourusername/lab-eks-pipeline.git

# Apply the configuration
kubectl apply -f k8s/argocd-app.yaml
```

### 5. Deploy Application

The deployment process is automated:
1. Push code to GitHub repository
2. GitHub Actions builds Docker images and updates Helm values
3. ArgoCD detects changes and synchronizes the application

### 6. Access Application

1. Connect to Windows instance via Systems Manager
2. Access the application at https://app.labinternal.example.com
3. Monitor using Grafana:
```bash
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
```

### 7. CI/CD Pipeline

The pipeline uses GitHub Actions with:
- Automatic versioning based on changes
- DockerHub image publishing
- ArgoCD deployment
- Infrastructure management

Container Images:
- Frontend: muzaparoff/lab-eks-cluster-frontend
- Backend: muzaparoff/lab-eks-cluster-backend
- Terraform: muzaparoff/terraform-runner

Example commit messages:
```bash
git commit -m "ver: complete rewrite of backend API"    # 1.0.0 -> 2.0.0
git commit -m "feat: add user authentication"           # 1.0.0 -> 1.1.0
git commit -m "fix: correct database connection issue"  # 1.0.0 -> 1.0.1
```

### 8. Cleanup
```bash
tf destroy
```

## Security Features

- Private VPC configuration
- Self-signed certificates managed via ACM
- Secure password generation
- Private ECR repositories
- IAM roles with least privilege
- Internal ALB (no public exposure)

## Monitoring

- Prometheus metrics collection
- Grafana dashboards
- EKS control plane logging
- RDS performance insights


