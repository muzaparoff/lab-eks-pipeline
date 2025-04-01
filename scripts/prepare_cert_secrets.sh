#!/bin/bash
set -e

# Check if certificates exist
if [ ! -f "certificates/certificate.crt" ] || [ ! -f "certificates/private.key" ]; then
    echo "Certificates not found in certificates/"
    exit 1
fi

# Base64 encode the entire files without modifying content
CERT_BODY=$(cat certificates/certificate.crt | base64 -w 0)
CERT_KEY=$(cat certificates/private.key | base64 -w 0)

echo "Add these values to GitHub secrets:"
echo -e "\nGH_CERT_BODY:"
echo "$CERT_BODY"
echo -e "\nGH_CERT_KEY:"
echo "$CERT_KEY"
