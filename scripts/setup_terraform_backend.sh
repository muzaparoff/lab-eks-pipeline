#!/bin/bash
set -e

# Check if bucket exists
BUCKET_NAME="lab-eks-terraform-state-6368"
aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null || {
    echo "Creating S3 bucket..."
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region us-east-1
}

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

# Create DynamoDB table
echo "Creating DynamoDB table..."
aws dynamodb create-table \
    --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-east-1

# Wait for table to be active
echo "Waiting for DynamoDB table to be active..."
aws dynamodb wait table-exists \
    --table-name terraform-state-lock \
    --region us-east-1

echo "Backend infrastructure setup complete!"
