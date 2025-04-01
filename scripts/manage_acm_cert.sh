#!/bin/bash
set -e

DOMAIN=${1:-app.labinternal.example.com}
CERT_DIR="certificates"

# Function to generate certificate
generate_cert() {
    mkdir -p $CERT_DIR
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout $CERT_DIR/private.key \
        -out $CERT_DIR/certificate.crt \
        -subj "/CN=${DOMAIN}" \
        -addext "subjectAltName=DNS:${DOMAIN}"
}

# Function to import certificate to ACM
import_cert() {
    CERT=$(cat $CERT_DIR/certificate.crt)
    KEY=$(cat $CERT_DIR/private.key)
    
    aws acm import-certificate \
        --certificate fileb://$CERT_DIR/certificate.crt \
        --private-key fileb://$CERT_DIR/private.key \
        --region us-east-1

    echo "Certificate ARN:"
    aws acm list-certificates --query "CertificateSummaryList[?DomainName=='${DOMAIN}'].CertificateArn" --output text
}

# Main execution
if [ "$1" == "--help" ]; then
    echo "Usage: $0 [domain_name]"
    exit 0
fi

generate_cert
import_cert
