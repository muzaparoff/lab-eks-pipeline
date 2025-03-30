#!/bin/bash
set -e

DOMAIN=${1:-app.labinternal.example.com}
CERT_DIR="certificates"

mkdir -p $CERT_DIR

# Generate private key and CSR
openssl req -newkey rsa:2048 -nodes \
  -keyout $CERT_DIR/private.key \
  -out $CERT_DIR/csr.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=${DOMAIN}"

# Generate self-signed certificate
openssl x509 -signkey $CERT_DIR/private.key \
  -in $CERT_DIR/csr.pem \
  -req -days 365 -out $CERT_DIR/certificate.crt

# Create combined PEM file for ACM
cat $CERT_DIR/certificate.crt $CERT_DIR/private.key > $CERT_DIR/certificate.pem

echo "Generated certificates in ./$CERT_DIR:"
ls -l $CERT_DIR
