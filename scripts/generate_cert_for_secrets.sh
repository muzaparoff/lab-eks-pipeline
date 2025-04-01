#!/bin/bash
set -e

DOMAIN=${1:-app.labinternal.example.com}
CERT_DIR="certificates"

mkdir -p $CERT_DIR

# Generate private key and certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout $CERT_DIR/private.key \
  -out $CERT_DIR/certificate.crt \
  -subj "/CN=${DOMAIN}"

# Convert to base64 for GitHub secrets
echo "Certificate (add to GH_CERT_BODY secret):"
base64 -w 0 < $CERT_DIR/certificate.crt
echo -e "\n\nPrivate key (add to GH_CERT_KEY secret):"
base64 -w 0 < $CERT_DIR/private.key
