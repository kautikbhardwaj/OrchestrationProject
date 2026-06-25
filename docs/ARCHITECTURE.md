# System Architecture

```mermaid
flowchart LR
    Developer["Developer / GitHub"] -->|push webhook| Jenkins["Jenkins on EC2"]
    Jenkins -->|build and push| ECR["Amazon ECR<br/>3 repositories"]
    Jenkins -->|Helm upgrade| EKS["Amazon EKS"]

    User["Application user"] --> LB["AWS Load Balancer"]
    LB --> Frontend["Frontend pods<br/>NGINX + React"]
    Frontend --> Hello["Hello-service pods"]
    Frontend --> Profile["Profile-service pods"]
    Profile --> Mongo["MongoDB PVC<br/>or external MongoDB"]

    HPA["Horizontal Pod Autoscalers"] --> Frontend
    HPA --> Hello
    HPA --> Profile
    EKS --> CW["CloudWatch<br/>metrics and logs"]
    CW --> Alarm["CloudWatch alarms"]
    Jenkins --> SNS["SNS deployment topic"]
    Alarm --> SNS
    SNS --> Chat["Amazon Q chat applications<br/>Slack / Microsoft Teams"]
```

## Design decisions

- Three independent images allow each component to be built, released, and
  scaled separately.
- The browser communicates only with the frontend. NGINX proxies `/api/hello`
  and `/api/profile` to Kubernetes services, so cluster DNS names are not
  exposed to the browser.
- Every stateless component starts with two replicas and has CPU-based
  horizontal autoscaling from 2 to 6 replicas.
- Readiness probes prevent traffic from reaching unavailable pods. The profile
  readiness endpoint checks MongoDB connectivity.
- Pod disruption budgets preserve one available replica during voluntary node
  maintenance.
- MongoDB is included for an academic/demo environment. For production, set
  `mongodb.enabled=false` and provide an external database URL through a
  Kubernetes Secret.
- Images use immutable Git commit tags as well as the convenience `latest` tag.

## Request flow

1. The load balancer sends traffic to the frontend service.
2. NGINX serves the React files.
3. `/api/hello` is proxied to `hello-service:3001`.
4. `/api/profile/*` is proxied to `profile-service:3002`.
5. The profile service reads and writes user records in MongoDB.

## CI/CD flow

1. A push to GitHub invokes the Jenkins webhook.
2. Jenkins checks out the commit, tests/builds the frontend, and verifies
   backend dependencies.
3. Jenkins builds three Docker images.
4. Images are scanned on push and stored in separate ECR repositories.
5. Jenkins authenticates to EKS and runs `helm upgrade --install`.
6. Helm waits for a successful rollout.
7. Jenkins optionally publishes success or failure to SNS.
