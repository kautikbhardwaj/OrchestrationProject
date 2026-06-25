# Jenkins Configuration

## Recommended plugins

- Pipeline
- Git
- GitHub
- Credentials Binding
- AWS Credentials
- Workspace Cleanup

The Jenkins agent also needs Git, Docker, Node.js/npm, AWS CLI v2, `kubectl`,
Helm, and Bash. Add the `jenkins` user to the Docker group and restart Jenkins
afterward.

## Credentials

Create one credential:

| Jenkins ID | Type | Purpose |
|---|---|---|
| `kautik-mern-aws` | AWS Credentials | ECR, EKS, and optional SNS access |

Prefer an EC2 instance profile and short-lived credentials in a real
environment. Never place AWS keys in the Jenkinsfile.

## Pipeline job

1. Select **New Item**.
2. Choose **Pipeline**.
3. Select **Pipeline script from SCM**.
4. Choose Git and enter your fork URL.
5. Use branch `*/main`.
6. Set script path to `Jenkinsfile`.
7. Save and select **Build Now**.

The first build can leave `DEPLOY_TO_EKS=false` to validate CI and ECR before
cluster access is configured.

## GitHub webhook

In the fork, open **Settings → Webhooks → Add webhook**:

- Payload URL: `https://YOUR_JENKINS_URL/github-webhook/`
- Content type: `application/json`
- Event: push events
- Active: enabled

The Jenkins GitHub plugin's `githubPush()` trigger is already declared in the
Jenkinsfile. Confirm the webhook delivery returns HTTP 200 and that a new
commit starts a build.

## Required AWS permissions

The Jenkins principal needs:

- ECR authorization and repository/image operations
- `sts:GetCallerIdentity`
- EKS cluster description
- permission to publish to the selected SNS topic
- an EKS access entry/RBAC authorization to deploy into the cluster

Use [infra/jenkins-iam-policy.json](../infra/jenkins-iam-policy.json) as a
starting point and scope the account, Region, repositories, cluster, and topic
for your environment.

## Pipeline stages

1. Checkout
2. Frontend test/build and backend dependency verification
3. Docker image builds
4. ECR authentication and push
5. Helm deployment to EKS
6. SNS success/failure notification

The immutable image tag is the first eight characters of the Git commit SHA.
