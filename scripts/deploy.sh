#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-ap-south-1}"
CLUSTER="${EKS_CLUSTER:-mern-eks}"
NAMESPACE="${K8S_NAMESPACE:-mern-app}"
TAG="${IMAGE_TAG:-latest}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER"

helm upgrade --install mern-app ./helm/mern-app \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set image.tag="$TAG" \
  --set image.frontend.repository="$REGISTRY/mern-frontend" \
  --set image.hello.repository="$REGISTRY/mern-hello-service" \
  --set image.profile.repository="$REGISTRY/mern-profile-service" \
  --wait --timeout 10m

kubectl rollout status deployment/frontend -n "$NAMESPACE" --timeout=5m
kubectl rollout status deployment/hello-service -n "$NAMESPACE" --timeout=5m
kubectl rollout status deployment/profile-service -n "$NAMESPACE" --timeout=5m
kubectl get service frontend -n "$NAMESPACE"
