#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-ap-south-1}"
TOPIC_NAME="${SNS_TOPIC_NAME:-mern-deployment-events}"

aws sns create-topic --region "$REGION" --name "$TOPIC_NAME" --query TopicArn --output text
