#!/bin/bash
set -e

# Read certificate files
CERT_PATH="certificates/certificate.crt"
KEY_PATH="certificates/private.key"

if [ ! -f "$CERT_PATH" ] || [ ! -f "$KEY_PATH" ]; then
    echo "Certificate files not found"
    exit 1
fi

# Function to properly encode certificate content
encode_cert() {
    local content="$1"
    # Remove any existing base64 encoding
    if echo "$content" | base64 -d > /dev/null 2>&1; then
        content=$(echo "$content" | base64 -d)
    fi
    # Ensure proper line endings and base64 encode
    echo "$content" | tr -d '\r' | base64 -w 0
}

# Read and encode certificate and key
CERT_CONTENT=$(cat "$CERT_PATH")
KEY_CONTENT=$(cat "$KEY_PATH")

CERT_BODY=$(encode_cert "$CERT_CONTENT")
CERT_KEY=$(encode_cert "$KEY_CONTENT")

echo "Add these properly encoded values to GitHub secrets:"
echo -e "\nGH_CERT_BODY:"
echo "$CERT_BODY"
echo -e "\nGH_CERT_KEY:"
echo "$CERT_KEY"

# Test decode
echo -e "\nValidating encoded values..."
echo "$CERT_BODY" | base64 -d | grep -q "BEGIN CERTIFICATE" && echo "Certificate validation: OK" || echo "Certificate validation: FAILED"
echo "$CERT_KEY" | base64 -d | grep -q "BEGIN PRIVATE KEY" && echo "Private key validation: OK" || echo "Private key validation: FAILED"
