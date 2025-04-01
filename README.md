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

## Certificate Setup

Before running Terraform, set up the ACM certificate:

```bash
# Generate and import certificate
./scripts/manage_acm_cert.sh app.labinternal.example.com
```

The script will:
- Generate a self-signed certificate
- Import it to ACM
- Store files in ./certificates directory (gitignored)

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

## Development and Testing Workflow

### 1. Local Development

```bash
# Clone repository
git clone https://github.com/yourusername/lab-eks-pipeline.git
cd lab-eks-pipeline

# Setup local environment
./scripts/setup_terraform_backend.sh  # Create S3 bucket and DynamoDB table
./scripts/generate_password.sh        # Generate RDS password
./scripts/manage_acm_cert.sh         # Generate and import certificate
```

### 2. Making Changes

For application changes:
```bash
# Frontend/Backend changes
cd app/frontend  # or app/backend
# Make your changes
git commit -m "feat: add new feature"  # Triggers CI pipeline
git push

# Watch ArgoCD sync status
kubectl get application -n argocd lab-app -w
```

For infrastructure changes:
```bash
# Test Terraform changes locally
cd terraform
terraform init
terraform plan

# Commit and push
git commit -m "feat: update infrastructure"
git push
```

### 3. Versioning

The repository uses semantic versioning:
- `ver:` prefix for major version changes
- `feat:` prefix for feature changes
- `fix:` prefix for bug fixes

Example:
```bash
git commit -m "ver: complete rewrite of backend API"    # 1.0.0 -> 2.0.0
git commit -m "feat: add user authentication"           # 1.0.0 -> 1.1.0
git commit -m "fix: correct database connection issue"  # 1.0.0 -> 1.0.1
```

### 4. Testing Changes

Frontend testing:
```bash
# Local testing with Docker
cd app/frontend
docker build -t frontend-test .
docker run -p 5000:5000 \
  -e BACKEND_URL=http://localhost:5001 \
  frontend-test
```

Backend testing:
```bash
# Local testing with Docker
cd app/backend
docker build -t backend-test .
docker run -p 5001:5000 \
  -e DB_HOST=localhost \
  -e DB_NAME=testdb \
  -e DB_USER=testuser \
  -e DB_PASSWORD=testpass \
  backend-test
```

Infrastructure testing:
```bash
# Test Terraform changes
cd terraform
terraform plan                  # Review changes
terraform apply -target=module.vpc  # Test specific module
terraform destroy -target=module.vpc  # Clean up test resources
```

### 5. Monitoring Deployments

```bash
# Watch ArgoCD sync status
kubectl get application -n argocd lab-app -w

# Check pod status
kubectl get pods -n lab-app

# View logs
kubectl logs -n lab-app -l app=frontend -f  # Frontend logs
kubectl logs -n lab-app -l app=backend -f   # Backend logs

# Monitor through Grafana
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
# Access at http://localhost:3000
```

### 6. Troubleshooting

```bash
# Check ArgoCD status
argocd app get lab-app
argocd app sync lab-app --force

# Reset stuck Terraform state
./scripts/remove_tf_lock.sh

# Validate certificates
./scripts/validate_and_fix_cert.sh

# Clean up resources for fresh start
./scripts/cleanup_resources.sh
```

## Manual Testing in Windows Instance

1. Connect to Windows Instance:
```bash
# Get Windows instance ID
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=lab-eks-windows" \
  --query 'Reservations[].Instances[?State.Name==`running`].InstanceId' \
  --output text

# Start Session Manager session
aws ssm start-session --target <instance-id>
```

2. Open Edge Browser in Windows:
   - Press Windows + R
   - Type `msedge` and press Enter

3. Access the Application:
   - Navigate to: `https://app.labinternal.example.com`
   - You should see the frontend displaying data from backend
   - Data refreshes every 10 seconds automatically

4. Verify Database Updates:
   - Each refresh shows latest value from PostgreSQL
   - Format: "Hello Lab-commit X" where X increments

5. Troubleshooting:
   - Check certificate warning (expected with self-signed cert)
   - Verify DNS resolution: `nslookup app.labinternal.example.com`
   - Test backend directly: `curl http://backend-service:5000/data`
   - Check Route53 record: `aws route53 list-resource-record-sets --hosted-zone-id <zone-id>`

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

## Testing via Windows Instance

1. Connect to Windows Instance:
```bash
# Get the instance ID of your Windows instance
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=lab-eks-windows" \
  --query 'Reservations[].Instances[?State.Name==`running`].InstanceId' \
  --output text

# Connect via Session Manager in AWS Console:
# 1. Go to AWS Console → EC2 → Instances
# 2. Select your Windows instance
# 3. Click "Connect" button
# 4. Choose "Session Manager" tab
# 5. Click "Connect"
```

2. Test Application Access:
- Open Edge browser in the Windows instance
- Navigate to: `https://app.labinternal.example.com`
- You should see:
  * Frontend displaying "Hello Lab-commit X"
  * Version number
  * Auto-refresh every 10 seconds

3. Verify Database Connection:
- Watch the value increment
- Each refresh should show latest data from RDS

4. Troubleshooting:
- If certificate warning appears, this is normal (self-signed cert)
- If page doesn't load:
  ```bash
  # Test DNS resolution
  nslookup app.labinternal.example.com
  
  # Test backend directly
  curl http://backend-service:5000/data
  
  # Check pods status
  kubectl get pods -n lab-app
  ```


