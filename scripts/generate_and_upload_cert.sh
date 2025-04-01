#!/bin/bash
set -e

DOMAIN=${1:-app.labinternal.example.com}
CERT_DIR="certificates"

mkdir -p $CERT_DIR

# Check if certificate already exists in ACM
EXISTING_CERT=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='${DOMAIN}'].CertificateArn" --output text)

if [ ! -z "$EXISTING_CERT" ]; then
    echo "Certificate already exists in ACM with ARN: $EXISTING_CERT"
    exit 0
fi

# Generate certificate only if it doesn't exist
openssl req -x509 -newkey rsa:2048 -sha256 -days 365 -nodes \
  -keyout $CERT_DIR/private.key \
  -out $CERT_DIR/certificate.crt \
  -subj "/CN=${DOMAIN}" \
  -addext "subjectAltName=DNS:${DOMAIN},DNS:*.${DOMAIN}"

# Base64 encode entire files
CERT_BODY=$(cat $CERT_DIR/certificate.crt | base64 -w 0)
CERT_KEY=$(cat $CERT_DIR/private.key | base64 -w 0)

echo "Add these values to GitHub secrets:"
echo -e "\nGH_CERT_BODY:"
echo "$CERT_BODY"
echo -e "\nGH_CERT_KEY:"
echo "$CERT_KEY"
