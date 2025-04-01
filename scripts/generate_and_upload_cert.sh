#!/bin/bash
set -e

DOMAIN=${1:-app.labinternal.example.com}
CERT_DIR="certificates"

# Create certificates directory if it doesn't exist
mkdir -p $CERT_DIR

# Generate self-signed certificate with proper extensions
cat > $CERT_DIR/openssl.conf <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = ${DOMAIN}

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = *.${DOMAIN}
EOF

# Generate private key and certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout $CERT_DIR/private.key \
  -out $CERT_DIR/certificate.crt \
  -config $CERT_DIR/openssl.conf

# Base64 encode for GitHub secrets
CERT_BODY=$(cat $CERT_DIR/certificate.crt | base64 -w 0)
CERT_KEY=$(cat $CERT_DIR/private.key | base64 -w 0)

echo "Add these values to your GitHub repository secrets:"
echo -e "\nGH_CERT_BODY:"
echo "$CERT_BODY"
echo -e "\nGH_CERT_KEY:"
echo "$CERT_KEY"

# Clean up config file
rm $CERT_DIR/openssl.conf
