#!/usr/bin/env bash
set -euo pipefail

CLUSTER="${EKS_CLUSTER:-mern-eks}"
ROLE_NAME="${CLOUDWATCH_ROLE_NAME:-EKS-CloudWatch-Agent-Role}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

for addon in eks-pod-identity-agent metrics-server; do
  aws eks describe-addon --cluster-name "$CLUSTER" \
    --addon-name "$addon" >/dev/null 2>&1 ||
    aws eks create-addon --cluster-name "$CLUSTER" --addon-name "$addon"
  aws eks wait addon-active --cluster-name "$CLUSTER" --addon-name "$addon"
done

if ! aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  TRUST_POLICY="$(mktemp)"
  trap 'rm -f "$TRUST_POLICY"' EXIT
  printf '%s\n' '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"pods.eks.amazonaws.com"},"Action":["sts:AssumeRole","sts:TagSession"]}]}' > "$TRUST_POLICY"
  aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document "file://${TRUST_POLICY}"
fi

aws iam attach-role-policy --role-name "$ROLE_NAME" \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
aws iam attach-role-policy --role-name "$ROLE_NAME" \
  --policy-arn arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess

aws eks create-pod-identity-association \
  --cluster-name "$CLUSTER" \
  --namespace amazon-cloudwatch \
  --service-account cloudwatch-agent \
  --role-arn "$ROLE_ARN" 2>/dev/null || true

aws eks describe-addon --cluster-name "$CLUSTER" \
  --addon-name amazon-cloudwatch-observability >/dev/null 2>&1 ||
  aws eks create-addon --cluster-name "$CLUSTER" \
    --addon-name amazon-cloudwatch-observability

aws eks wait addon-active --cluster-name "$CLUSTER" \
  --addon-name amazon-cloudwatch-observability
