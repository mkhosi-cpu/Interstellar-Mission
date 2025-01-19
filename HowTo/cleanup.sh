#!/bin/bash

# Variables
KEY_NAME="mission-control-key"
SECURITY_GROUP_NAME="mission-control-sg"
VPC_NAME="mission-control-vpc"
SUBNET_NAME="mission-control-subnet"
IAM_ROLE_NAME="mission-control-role"
IAM_INSTANCE_PROFILE="mission-control-instance-profile"

# Terminate EC2 Instances
INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=mission-control-instance" --query "Reservations[*].Instances[*].InstanceId" --output text)
if [ -n "$INSTANCE_IDS" ]; then
    for INSTANCE_ID in $INSTANCE_IDS; do
        aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"
        aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID"
    done
fi

# Delete Key Pair
aws ec2 delete-key-pair --key-name $KEY_NAME
rm -f $KEY_NAME.pem

# Delete Security Groups
SECURITY_GROUP_IDS=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" --query "SecurityGroups[*].GroupId" --output text)
if [ -n "$SECURITY_GROUP_IDS" ]; then
    for SECURITY_GROUP_ID in $SECURITY_GROUP_IDS; do
        aws ec2 delete-security-group --group-id "$SECURITY_GROUP_ID"
    done
fi

# Delete Subnets
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$SUBNET_NAME" --query "Subnets[*].SubnetId" --output text)
if [ -n "$SUBNET_IDS" ]; then
    for SUBNET_ID in $SUBNET_IDS; do
        aws ec2 delete-subnet --subnet-id "$SUBNET_ID"
    done
fi

# Delete Internet Gateway
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME" --query "Vpcs[*].VpcId" --output text)
if [ -n "$VPC_ID" ]; then
    IGW_IDS=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[*].InternetGatewayId" --output text)
    for IGW_ID in $IGW_IDS; do
        aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
        aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID"
    done
fi

# Delete Route Tables
ROUTE_TABLE_IDS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query "RouteTables[*].RouteTableId" --output text)
if [ -n "$ROUTE_TABLE_IDS" ]; then
    for ROUTE_TABLE_ID in $ROUTE_TABLE_IDS; do
        aws ec2 delete-route-table --route-table-id "$ROUTE_TABLE_ID"
    done
fi

# Delete VPC
if [ -n "$VPC_ID" ]; then
    aws ec2 delete-vpc --vpc-id "$VPC_ID"
fi

# Delete IAM Role and Instance Profile
aws iam remove-role-from-instance-profile --instance-profile-name $IAM_INSTANCE_PROFILE --role-name $IAM_ROLE_NAME 2>/dev/null
aws iam delete-instance-profile --instance-profile-name $IAM_INSTANCE_PROFILE 2>/dev/null
aws iam detach-role-policy --role-name $IAM_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess 2>/dev/null
aws iam delete-role --role-name $IAM_ROLE_NAME 2>/dev/null

echo "Cleanup complete!"
