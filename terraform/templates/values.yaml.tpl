frontend:
  image:
    repository: muzaparoff/lab-eks-cluster-frontend
    tag: latest
  env:
    - name: BACKEND_URL
      value: http://backend-service:5000
    - name: APP_VERSION
      value: "${app_version}"

backend:
  image:
    repository: muzaparoff/lab-eks-cluster-backend
    tag: latest
  env:
    - name: DB_HOST
      value: ${rds_endpoint}
    - name: DB_NAME
      value: ${db_name}
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: username
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: password

ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internal
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
  host: ${domain_name}
