#!/bin/bash
set -e

# Delete existing ALB controller helm release if exists
helm delete aws-load-balancer-controller -n kube-system || true

# Delete existing ACM certificate
CERT_ARN=$(aws acm list-certificates --query 'CertificateSummaryList[?DomainName==`app.labinternal.example.com`].CertificateArn' --output text)
if [ ! -z "$CERT_ARN" ]; then
  aws acm delete-certificate --certificate-arn $CERT_ARN
fi

echo "Cleanup complete. You can now run terraform apply again."
