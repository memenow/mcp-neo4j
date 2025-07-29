# MCP Neo4j Kubernetes Deployment

This directory contains Kubernetes deployment configurations for MCP Neo4j services optimized for Google Kubernetes Engine (GKE) Autopilot.

## Services Deployed

- **mcp-neo4j-cypher**: Natural language to Cypher queries service
- **mcp-neo4j-memory**: Knowledge graph memory service 
- **mcp-neo4j-data-modeling**: Interactive graph data modeling service

## Architecture

The deployment follows Google Cloud and GKE Autopilot best practices:

- **Minimal Resources**: Uses GKE Autopilot's minimal resource requests (50m CPU, 128Mi memory)
- **Security Hardened**: Non-root containers, read-only root filesystem, no privileged escalation
- **Auto-scaling**: Horizontal Pod Autoscaler (HPA) based on CPU and memory utilization
- **High Availability**: Pod Disruption Budgets (PDB) ensure service availability during updates
- **Production Ready**: Health checks, resource limits, proper labeling

## Prerequisites

1. GKE Autopilot cluster
2. Neo4j instance running in the `neo4j` namespace (StatefulSet: `prod-yinyang-agent-neo4j`)
3. kubectl configured to access your cluster
4. Docker images built and pushed to GitHub Container Registry

## Quick Deploy

```bash
# Navigate to deployment directory
cd k8s-deployment

# Deploy all services
./deploy.sh
```

## Manual Deployment

```bash
# Create namespace
kubectl create namespace neo4j

# Apply all configurations
kubectl apply -k .

# Check deployment status
kubectl get pods -n neo4j
kubectl get services -n neo4j
kubectl get ingress -n neo4j
```

## Configuration

### Environment Variables

Configure the following in `configmap.yaml`:

- `NEO4J_URI`: Connection URI to Neo4j (default: `bolt://prod-yinyang-agent-neo4j:7687`)
- `NEO4J_DATABASE`: Database name (default: `neo4j`)
- Service ports for each MCP service

### Secrets

Update `secret.yaml` with your Neo4j credentials:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mcp-neo4j-secret
  namespace: neo4j
type: Opaque
data:
  NEO4J_USERNAME: <base64-encoded-username>
  NEO4J_PASSWORD: <base64-encoded-password>
```

### Ingress

The ingress configuration uses environment variable support for open source compatibility. The domain is configured through GitHub Secrets:

```yaml
spec:
  rules:
  - host: INGRESS_HOST  # Replaced during deployment with actual domain
    http:
      paths:
      - path: /v1/neo4j/cypher/*
      - path: /v1/neo4j/memory/*
      - path: /v1/neo4j/modeling/*
```

**Required GitHub Secret:**
- `INGRESS_HOST`: Domain name for ingress (e.g., `mcp.example.com`)

## Service Endpoints

After deployment, services will be available at (replace with your actual domain):

- Cypher Service: `https://<your-domain>/v1/neo4j/cypher/api/mcp/`
- Memory Service: `https://<your-domain>/v1/neo4j/memory/api/mcp/`
- Data Modeling: `https://<your-domain>/v1/neo4j/modeling/api/mcp/`

## Monitoring

The deployment includes:

- Prometheus ServiceMonitor for metrics collection
- Health check endpoints at `/health`
- Readiness and liveness probes

## Scaling

Auto-scaling is configured with HPA:

- **CPU Target**: 70% utilization
- **Memory Target**: 80% utilization
- **Min Replicas**: 1
- **Max Replicas**: 5 (cypher/memory), 3 (data-modeling)

Manual scaling:

```bash
kubectl scale deployment mcp-neo4j-cypher --replicas=3 -n neo4j
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n neo4j
kubectl describe pod <pod-name> -n neo4j
```

### View Logs

```bash
kubectl logs -f deployment/mcp-neo4j-cypher -n neo4j
```

### Check Service Connectivity

```bash
kubectl port-forward service/mcp-neo4j-cypher 8001:8001 -n neo4j
curl http://localhost:8001/health
```

### Neo4j Connection Issues

1. Ensure Neo4j StatefulSet is running:
   ```bash
   kubectl get sts prod-yinyang-agent-neo4j -n neo4j
   kubectl scale sts prod-yinyang-agent-neo4j --replicas=1 -n neo4j
   ```

2. Verify Neo4j service is accessible:
   ```bash
   kubectl get svc -n neo4j | grep neo4j
   ```

## Security

- All containers run as non-root user (UID 1000)
- Read-only root filesystem
- Minimal Linux capabilities
- Network policies can be added for additional security

## Cost Optimization

- Uses GKE Autopilot's pay-per-pod model
- Minimal resource requests to reduce costs
- Auto-scaling to handle variable loads efficiently

## CI/CD Integration

GitHub Actions workflows automatically:

1. Build and push Docker images on code changes
2. Deploy to GKE on successful builds
3. Verify deployment health

## Production Checklist

- [x] Environment variable support for domain configuration  
- [x] Configure SSL certificates (GKE managed certificates)
- [ ] Set up monitoring and alerting
- [ ] Configure backup strategy for Neo4j
- [ ] Review and adjust resource limits based on usage
- [ ] Enable network policies if required
- [ ] Set up log aggregation (GKE logging enabled by default)