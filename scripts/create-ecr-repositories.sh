#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-ap-south-1}"

for repository in mern-frontend mern-hello-service mern-profile-service; do
  aws ecr describe-repositories --region "$REGION" --repository-names "$repository" >/dev/null 2>&1 ||
    aws ecr create-repository \
      --region "$REGION" \
      --repository-name "$repository" \
      --image-scanning-configuration scanOnPush=true \
      --encryption-configuration encryptionType=AES256
done
