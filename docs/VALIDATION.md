# Validation and Submission Evidence

## Functional checks

```bash
APP_HOST="$(kubectl get svc frontend -n mern-app \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

curl "http://${APP_HOST}:8080/health"
curl "http://${APP_HOST}:8080/api/hello"
curl "http://${APP_HOST}:8080/api/profile/fetchUser"

curl -X POST "http://${APP_HOST}:8080/api/profile/addUser" \
  -H "Content-Type: application/json" \
  -d '{"name":"Hero Vired","age":25}'

curl "http://${APP_HOST}:8080/api/profile/fetchUser"
```

Expected results:

- `/health` returns `OK`.
- `/api/hello` returns `{"msg":"Hello World"}`.
- The POST returns HTTP 201.
- The created profile appears in `fetchUser`.

## Scaling checks

```bash
kubectl get deployment,pods,hpa,pdb -n mern-app
kubectl top pods -n mern-app
```

For an HPA demonstration, generate traffic from another terminal and capture
`kubectl get hpa -n mern-app -w`. Scaling occurs only after the metrics server
has metrics and CPU crosses the target.

## Logging and monitoring checks

- EKS control-plane logs appear in CloudWatch Logs.
- Container Insights shows cluster, node, pod, and container metrics.
- Application container logs are searchable in CloudWatch Logs.
- The node CPU alarm exists and points to the SNS topic.
- A Jenkins success/failure notification reaches Slack or Microsoft Teams if
  the bonus is enabled.

## Screenshots to include

- GitHub fork and recent commits
- Three ECR repositories with image tags
- Successful Jenkins pipeline stages
- GitHub webhook successful delivery
- EKS cluster and managed nodes
- `kubectl get pods,svc,hpa,pdb,pvc -n mern-app`
- Working frontend and API response
- CloudWatch Container Insights dashboard and logs
- CloudWatch alarm
- SNS topic and chat message for the bonus

Do not include AWS secret keys, Jenkins passwords, database credentials, or
session tokens in screenshots.

## Final repository checklist

- [x] Add the student name and final GitHub repository URL.
- [x] Configure the GitHub push webhook for the Jenkins pipeline.
- [ ] Commit all files and push to your fork.
- [ ] Confirm the repository is visible to the evaluator.
- [ ] Add screenshots to `docs/evidence/` and reference them in a report.
- [ ] Put the final repository URL in `SUBMISSION_LINK.txt`.
- [ ] Upload that text file, Word document, or PDF to Vlearn.
