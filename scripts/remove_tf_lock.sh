#!/bin/bash
set -e

BUCKET_NAME="lab-eks-terraform-state-6368"
TABLE_NAME="terraform-state-lock"
LOCK_ID="d9ee5086-1844-9b8f-d7ae-9bea12fae920"

echo "Checking for stale lock..."
aws dynamodb get-item \
    --table-name $TABLE_NAME \
    --key '{"LockID": {"S": "lab-eks-terraform-state-6368/terraform.tfstate"}}' \
    --region us-east-1

echo "Removing stale lock..."
aws dynamodb delete-item \
    --table-name $TABLE_NAME \
    --key '{"LockID": {"S": "lab-eks-terraform-state-6368/terraform.tfstate"}}' \
    --region us-east-1

echo "Lock removed. You can now run Terraform commands."
