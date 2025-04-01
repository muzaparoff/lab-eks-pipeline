#!/bin/bash
set -e

# Apply ArgoCD namespace and CRDs
kubectl apply -f k8s/argocd/namespace.yaml
kubectl apply -f k8s/argocd/crds.yaml

# Wait for ArgoCD to be ready
kubectl wait --namespace argocd \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=argocd-server \
  --timeout=300s

# Create project
kubectl apply -f k8s/argocd/app-project.yaml

# Get the admin password
echo "ArgoCD Admin Password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo

# Port forward instructions
echo "To access ArgoCD UI, run:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
