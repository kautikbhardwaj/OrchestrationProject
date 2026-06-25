#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-ap-south-1}"
CLUSTER="${EKS_CLUSTER:-mern-eks}"
: "${SNS_TOPIC_ARN:?Set SNS_TOPIC_ARN before running this script}"

aws cloudwatch put-metric-alarm \
  --region "$REGION" \
  --alarm-name "${CLUSTER}-high-node-cpu" \
  --alarm-description "EKS worker-node CPU exceeded 80 percent for 10 minutes" \
  --namespace ContainerInsights \
  --metric-name node_cpu_utilization \
  --dimensions "Name=ClusterName,Value=${CLUSTER}" \
  --statistic Average \
  --period 300 \
  --evaluation-periods 2 \
  --datapoints-to-alarm 2 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --treat-missing-data notBreaching \
  --alarm-actions "$SNS_TOPIC_ARN" \
  --ok-actions "$SNS_TOPIC_ARN"
