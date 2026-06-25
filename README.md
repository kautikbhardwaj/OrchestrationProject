# Orchestration and Scaling Project

This repository contains a submission-ready implementation of the sample MERN
application using Docker, Amazon ECR, Jenkins, Amazon EKS, Helm, CloudWatch, and
optional SNS ChatOps notifications.

## Components

- `frontend`: React application served by unprivileged NGINX
- `hello-service`: stateless Node.js API
- `profile-service`: Node.js API backed by MongoDB
- `mongodb`: local/demo database; an external MongoDB URL can be used in EKS

## Quick local validation

Prerequisite: Docker Desktop.

```bash
docker compose up --build -d
curl http://localhost:8080/health
curl http://localhost:8080/api/hello
curl http://localhost:8080/api/profile/fetchUser
docker compose down
```

Open <http://localhost:8080> in a browser.

Add sample data:

```bash
curl -X POST http://localhost:8080/api/profile/addUser \
  -H "Content-Type: application/json" \
  -d '{"name":"Student","age":25}'
```

## Repository layout

```text
backend/                 Node.js microservices and Dockerfiles
frontend/                React app, NGINX proxy, and Dockerfile
helm/mern-app/           Kubernetes Helm chart
infra/                   EKS and Jenkins infrastructure assets
scripts/                 ECR, deployment, CloudWatch, alarm, and SNS scripts
docs/                    Architecture, setup, validation, and evidence guide
Jenkinsfile              CI/CD pipeline
docker-compose.yml       Local end-to-end environment
```

## Recommended execution order

1. Fork this repository and configure the `upstream` remote.
2. Validate locally with Docker Compose.
3. Configure AWS CLI and create the ECR repositories.
4. Create the EKS cluster.
5. Enable CloudWatch observability.
6. Configure Jenkins credentials, tools, and pipeline.
7. Add the GitHub webhook.
8. Run the pipeline and validate the public application.
9. Collect screenshots and submit the fork URL.

Full instructions: [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)

Architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

Jenkins setup: [docs/JENKINS.md](docs/JENKINS.md)

Validation and evidence: [docs/VALIDATION.md](docs/VALIDATION.md)

> AWS resources in this project incur charges. Delete the EKS cluster, load
> balancer, EBS volume, ECR images, EC2 Jenkins host, and CloudWatch resources
> after evaluation.
