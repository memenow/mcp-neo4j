# GitHub Actions Setup for GKE Deployment

Follow these steps to configure GitHub Actions for automated deployment to your GKE cluster.

## 1. Create GCP Service Account

```bash
# Set your project ID
export PROJECT_ID="your-gcp-project-id"

# Create service account
gcloud iam service-accounts create mcp-neo4j-deployer \
    --description="Service account for MCP Neo4j GitHub Actions deployment" \
    --display-name="MCP Neo4j Deployer"

# Grant necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:mcp-neo4j-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/container.developer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:mcp-neo4j-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# Create and download service account key
gcloud iam service-accounts keys create key.json \
    --iam-account=mcp-neo4j-deployer@$PROJECT_ID.iam.gserviceaccount.com
```

## 2. Configure GitHub Repository Secrets

Go to your GitHub repository: `https://github.com/BillDuke13/mcp-neo4j/settings/secrets/actions`

Add the following secrets:

### Required Secrets

| Secret Name | Value | Description |
|-------------|--------|-------------|
| `GCP_PROJECT_ID` | Your GCP project ID | GCP project identifier |
| `GKE_CLUSTER` | Your GKE cluster name | Name of your Autopilot cluster |
| `GKE_ZONE` | Your GKE zone/region | Zone where cluster is located |
| `GCP_SA_KEY` | Contents of key.json | Service account JSON key (entire file content) |

### Example Values (replace with your actual values)

```bash
# Example - replace with your actual values
GCP_PROJECT_ID: "my-gcp-project-12345"
GKE_CLUSTER: "autopilot-cluster-1"
GKE_ZONE: "us-central1"
```

## 3. Create Static IP (Optional but Recommended)

```bash
# Create static IP for ingress
gcloud compute addresses create mcp-neo4j-ip --global

# Get the IP address
gcloud compute addresses describe mcp-neo4j-ip --global --format="value(address)"
```

Update your DNS to point `mcp.memenow.net` to this IP address.

## 4. Verify GKE Cluster Configuration

Ensure your GKE cluster meets requirements:

```bash
# Check cluster status
gcloud container clusters describe $GKE_CLUSTER --zone=$GKE_ZONE

# Verify Autopilot mode
gcloud container clusters describe $GKE_CLUSTER --zone=$GKE_ZONE --format="value(autopilot.enabled)"
```

## 5. Test Local Deployment (Optional)

Before enabling GitHub Actions, test locally:

```bash
# Configure kubectl
gcloud container clusters get-credentials $GKE_CLUSTER --zone=$GKE_ZONE

# Create Neo4j secrets (update with your credentials)
kubectl create secret generic mcp-neo4j-secret \
    --from-literal=NEO4J_USERNAME="neo4j" \
    --from-literal=NEO4J_PASSWORD="your-password" \
    --namespace=neo4j --dry-run=client -o yaml > k8s-deployment/secret.yaml

# Deploy manually
cd k8s-deployment
./deploy.sh
```

## 6. Trigger GitHub Actions

Once secrets are configured:

1. Push changes to `main` branch
2. GitHub Actions will automatically:
   - Build Docker images
   - Push to GitHub Container Registry
   - Deploy to GKE
   - Verify deployment health

## 7. Monitor Deployment

Check deployment status:

```bash
# View GitHub Actions logs
# Go to: https://github.com/BillDuke13/mcp-neo4j/actions

# Check pods in cluster
kubectl get pods -n neo4j

# Check services
kubectl get services -n neo4j

# Check ingress
kubectl get ingress -n neo4j
```

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure service account has correct IAM roles
2. **Cluster Not Found**: Verify `GKE_CLUSTER` and `GKE_ZONE` values
3. **Image Pull Errors**: Check GitHub Container Registry permissions
4. **Neo4j Connection**: Ensure Neo4j StatefulSet is running with replicas=1

### Debug Commands

```bash
# Check GitHub Actions runner access
gcloud auth list

# Test cluster connectivity
kubectl cluster-info

# View detailed pod status
kubectl describe pod <pod-name> -n neo4j

# Check Neo4j connectivity
kubectl port-forward sts/prod-yinyang-agent-neo4j 7687:7687 -n neo4j
```

## Security Best Practices

- Use least-privilege IAM roles
- Rotate service account keys regularly
- Enable audit logging on GKE cluster
- Use Workload Identity (recommended for production)
- Store sensitive data in Kubernetes secrets, not ConfigMaps

## Next Steps

After successful deployment:

1. Configure monitoring and alerting
2. Set up backup strategy for Neo4j
3. Configure log aggregation
4. Test auto-scaling behavior
5. Set up CI/CD for application updates