#!/usr/bin/env bash

set -e

export AWS_DEFAULT_REGION="ap-southeast-2"
user_data=$(cat user-data.sh)
instance_count=${1:-1}

security_group_id=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=sample-app" \
  --query "SecurityGroups[0].GroupId" \
  --output text)

if [[ "$security_group_id" == "None" ]]; then
  security_group_id=$(aws ec2 create-security-group \
    --group-name "sample-app" \
    --description "Allow HTTP traffic into the sample app" \
    --output text \
    --query GroupId)
fi

authorize_output=$(aws ec2 authorize-security-group-ingress \
  --group-id "$security_group_id" \
  --protocol tcp \
  --port 80 \
  --cidr "0.0.0.0/0" 2>&1) || {
    if [[ "$authorize_output" != *"InvalidPermission.Duplicate"* ]]; then
      echo "$authorize_output" >&2
      exit 1
    fi
  }

image_id=$(aws ec2 describe-images \
  --owners amazon \
  --filters 'Name=name,Values=al2023-ami-2023.*-x86_64' \
  --query 'reverse(sort_by(Images, &CreationDate))[:1] | [0].ImageId' \
  --output text)

instance_ids=$(aws ec2 run-instances \
  --image-id "$image_id" \
  --instance-type "t2.micro" \
  --security-group-ids "$security_group_id" \
  --user-data "$user_data" \
  --count "$instance_count" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=sample-app}]' \
  --output text \
  --query 'Instances[*].InstanceId')

public_ips=$(aws ec2 describe-instances \
  --instance-ids $instance_ids \
  --output text \
  --query 'Reservations[*].Instances[*].PublicIpAddress')

echo "Instance Count = $instance_count"
echo "Instance IDs = $instance_ids"
echo "Security Group ID = $security_group_id"
echo "Public IPs = $public_ips"
