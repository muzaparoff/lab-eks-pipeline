#!/bin/bash
set -e

# Create namespace for ArgoCD if it doesn't exist
kubectl create namespace argocd || echo "Namespace argocd already exists"

# Install ArgoCD using the official manifest
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get the initial admin password
ARGO_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Initial Password: $ARGO_PASSWORD"

# Apply the application manifest
envsubst < ../k8s/argocd-app.yaml | kubectl apply -f -

echo "ArgoCD installation initiated. Wait a few minutes for pods to be ready."