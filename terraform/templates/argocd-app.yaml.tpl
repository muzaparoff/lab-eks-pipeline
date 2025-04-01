apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: lab-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${repo_url}
    targetRevision: HEAD  # Always uses latest commit
    path: helm/lab-app
    helm:
      valueFiles:
        - values.yaml
      values: |
        frontend:
          image:
            tag: ${app_version}  # Automatically updated by CI
        backend:
          image:
            tag: ${app_version}  # Automatically updated by CI
  destination:
    server: https://kubernetes.default.svc
    namespace: lab-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
