#!/bin/bash
set -e

# Check if certificates exist
if [ ! -f "certificates/certificate.crt" ] || [ ! -f "certificates/private.key" ]; then
    echo "Certificates not found in certificates/"
    exit 1
fi

# Extract content between markers and base64 encode
CERT_BODY=$(awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' certificates/certificate.crt | grep -v "BEGIN\|END\|---" | tr -d '\n' | base64)
CERT_KEY=$(awk '/BEGIN PRIVATE KEY/,/END PRIVATE KEY/' certificates/private.key | grep -v "BEGIN\|END\|---" | tr -d '\n' | base64)

echo "Add these values to GitHub secrets:"
echo -e "\nGH_CERT_BODY:"
echo "$CERT_BODY"
echo -e "\nGH_CERT_KEY:"
echo "$CERT_KEY"
