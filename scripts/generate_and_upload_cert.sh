#!/bin/bash
set -e

DOMAIN=${1:-app.labinternal.example.com}
CERT_DIR="certificates"

mkdir -p $CERT_DIR

# Generate clean certificate without chain
openssl req -x509 -newkey rsa:2048 -sha256 -days 365 -nodes \
  -keyout $CERT_DIR/private.key \
  -out $CERT_DIR/certificate.crt \
  -subj "/CN=${DOMAIN}" \
  -addext "subjectAltName=DNS:${DOMAIN},DNS:*.${DOMAIN}"

# Properly format and encode certificate
CERT_BODY=$(cat $CERT_DIR/certificate.crt | grep -v "CERTIFICATE" | tr -d '\n')
CERT_KEY=$(cat $CERT_DIR/private.key | grep -v "PRIVATE KEY" | tr -d '\n')

echo "Add these values to GitHub secrets:"
echo -e "\nGH_CERT_BODY:"
echo "-----BEGIN CERTIFICATE-----"
echo "$CERT_BODY" | fold -w 64
echo "-----END CERTIFICATE-----" | base64

echo -e "\nGH_CERT_KEY:"
echo "-----BEGIN PRIVATE KEY-----"
echo "$CERT_KEY" | fold -w 64
echo "-----END PRIVATE KEY-----" | base64
