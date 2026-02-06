#!/bin/bash

SG_ID="sg-0b1f7c3d25067bf9a"
AMI_ID="ami-0220d79f3f480ecf5"
SUBNET_ID="subnet-0bb417478919bf408"
ZONE_ID="Z07326442Z8C3IRLJ3030"
DOMAIN_NAME="cloudkarna.in"

for instance in "$@"; do

  # 🔹 Public IP ENABLED FOR ALL INSTANCES
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "t3.micro" \
    --subnet-id "$SUBNET_ID" \
    --security-group-ids "$SG_ID" \
    --associate-public-ip-address \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

  aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

  if [[ "$instance" == "frontend" ]]; then
    IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query 'Reservations[0].Instances[0].PublicIpAddress' \
      --output text)
    RECORD_NAME="frontend.${DOMAIN_NAME}"
  else
    IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query 'Reservations[0].Instances[0].PrivateIpAddress' \
      --output text)
    RECORD_NAME="${instance}.${DOMAIN_NAME}"
  fi

  echo "$instance → IP: $IP → DNS: $RECORD_NAME"

  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "{
      \"Comment\": \"Updating record\",
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"${RECORD_NAME}\",
          \"Type\": \"A\",
          \"TTL\": 1,
          \"ResourceRecords\": [{\"Value\": \"${IP}\"}]
        }
      }]
    }"

  echo "Record updated for $instance"
done