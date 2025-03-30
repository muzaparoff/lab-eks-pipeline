#!/bin/bash
set -e

# Read domain from first argument
DOMAIN="$1"

# Generate certificate
CERT=$(openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -subj "/CN=${DOMAIN}" 2>/dev/null | base64 -w 0)

# Generate private key
KEY=$(openssl genrsa 2048 2>/dev/null | base64 -w 0)

# Output JSON for Terraform external data source
cat <<EOF
{
  "certificate": "${CERT}",
  "private_key": "${KEY}"
}
EOF
