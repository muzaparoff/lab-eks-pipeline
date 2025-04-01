#!/bin/bash
set -e

# Get security group ID
SG_ID="$1"
if [ -z "$SG_ID" ]; then
    echo "Please provide security group ID"
    exit 1
fi

# Find and detach ENIs
echo "Finding ENIs attached to security group $SG_ID..."
ENIs=$(aws ec2 describe-network-interfaces --filters "Name=group-id,Values=$SG_ID" --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text)

for ENI in $ENIs; do
    echo "Detaching ENI $ENI..."
    ATTACHMENT=$(aws ec2 describe-network-interfaces --network-interface-ids $ENI --query 'NetworkInterfaces[0].Attachment.AttachmentId' --output text)
    if [ "$ATTACHMENT" != "None" ]; then
        aws ec2 detach-network-interface --attachment-id $ATTACHMENT --force
        echo "Waiting for detachment..."
        sleep 10
    fi
done

echo "ENI cleanup completed"
