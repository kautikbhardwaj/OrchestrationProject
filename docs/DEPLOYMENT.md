# Deployment Guide

Examples use `ap-south-1` and cluster name `mern-eks`.

## 1. Fork and synchronize

Fork the original repository in GitHub, then clone your fork:

```bash
git clone https://github.com/kautikbhardwaj/OrchestrationProject.git
cd OrchestrationProject
git remote add upstream https://github.com/UnpredictablePrashant/SampleMERNwithMicroservices.git
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

Never force-push when synchronizing coursework unless you understand which
commits will be replaced.

## 2. AWS CLI

```bash
aws configure
aws sts get-caller-identity
export AWS_REGION=ap-south-1
```

Do not commit access keys. Jenkins must store them in its Credentials store or
use an EC2 IAM role.

## 3. ECR

```bash
bash scripts/create-ecr-repositories.sh
aws ecr describe-repositories \
  --repository-names mern-frontend mern-hello-service mern-profile-service
```

## 4. EKS

Install `eksctl`, `kubectl`, and Helm, then create the cluster:

```bash
eksctl create cluster -f infra/eks-cluster.yaml
aws eks update-kubeconfig --region ap-south-1 --name mern-eks
kubectl get nodes
```

The cluster definition creates two private `t3.medium` managed nodes and
enables EKS control-plane logs.

Grant the Jenkins IAM principal cluster access. One option is an EKS access
entry:

```bash
aws eks create-access-entry \
  --cluster-name mern-eks \
  --principal-arn JENKINS_IAM_ROLE_OR_USER_ARN

aws eks associate-access-policy \
  --cluster-name mern-eks \
  --principal-arn JENKINS_IAM_ROLE_OR_USER_ARN \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster
```

For a real production environment, replace cluster-admin with a restricted
deployment role and namespace-level permissions.

## 5. CloudWatch metrics and logs

Enable the Amazon CloudWatch Observability EKS add-on:

```bash
export EKS_CLUSTER=mern-eks
bash scripts/enable-cloudwatch.sh
kubectl get pods -n amazon-cloudwatch
```

The script uses EKS Pod Identity and installs the current compatible add-on.
It also installs the EKS Pod Identity Agent and Kubernetes Metrics Server
add-ons. Metrics Server supplies CPU data to the horizontal pod autoscalers.
CloudWatch receives Container Insights metrics and container logs.

Create an SNS topic and a high-node-CPU alarm:

```bash
export SNS_TOPIC_ARN="$(bash scripts/create-sns-topic.sh)"
bash scripts/create-cloudwatch-alarm.sh
```

## 6. Jenkins deployment

Follow [JENKINS.md](JENKINS.md). The pipeline creates ECR repositories
idempotently, pushes images, deploys Helm, waits for rollouts, and optionally
publishes to SNS.

## 7. Manual Helm deployment

If you want to deploy without Jenkins:

```bash
export AWS_REGION=ap-south-1
export EKS_CLUSTER=mern-eks
export IMAGE_TAG=latest
bash scripts/deploy.sh
```

Use an external MongoDB:

```bash
kubectl create namespace mern-app
kubectl create secret generic external-mongodb \
  --namespace mern-app \
  --from-literal=MONGO_URL='mongodb+srv://USER:PASSWORD@HOST/mernapp'

helm upgrade --install mern-app helm/mern-app \
  --namespace mern-app \
  --set mongodb.enabled=false \
  --set mongodb.existingSecret=external-mongodb \
  --set image.frontend.repository=ACCOUNT.dkr.ecr.REGION.amazonaws.com/mern-frontend \
  --set image.hello.repository=ACCOUNT.dkr.ecr.REGION.amazonaws.com/mern-hello-service \
  --set image.profile.repository=ACCOUNT.dkr.ecr.REGION.amazonaws.com/mern-profile-service
```

## 8. Find the application URL

```bash
kubectl get service frontend -n mern-app
kubectl get pods,hpa,pdb,pvc -n mern-app
```

Wait until the frontend service has an external hostname, then open it using
HTTP. For HTTPS and a custom domain, enable the optional ingress and configure
the AWS Load Balancer Controller plus an ACM certificate.

## 9. ChatOps bonus

1. Create the SNS topic with `scripts/create-sns-topic.sh`.
2. Open **Amazon Q Developer in chat applications** in the AWS console.
3. Configure Slack or Microsoft Teams and authorize the workspace.
4. Create a channel configuration and associate the SNS topic.
5. Put the topic ARN in the Jenkins `SNS_TOPIC_ARN` parameter.
6. Run a pipeline and verify the success/failure message in the channel.

AWS reference:
<https://docs.aws.amazon.com/chatbot/latest/adminguide/what-is.html>

## 10. Cleanup

```bash
helm uninstall mern-app -n mern-app
eksctl delete cluster -f infra/eks-cluster.yaml
aws ecr delete-repository --repository-name mern-frontend --force
aws ecr delete-repository --repository-name mern-hello-service --force
aws ecr delete-repository --repository-name mern-profile-service --force
```

Also remove the Jenkins EC2 instance, SNS topic, retained CloudWatch log groups,
and any unused EBS volumes.
