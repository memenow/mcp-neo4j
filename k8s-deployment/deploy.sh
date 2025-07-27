#!/bin/bash

set -e

echo "Deploying MCP Neo4j services to GKE..."

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: kubectl is not configured. Please configure kubectl to connect to your GKE cluster."
    exit 1
fi

# Create namespace if it doesn't exist
kubectl create namespace neo4j --dry-run=client -o yaml | kubectl apply -f -

# Apply kustomization
echo "Applying Kubernetes configurations..."
kubectl apply -k .

# Wait for deployments to be ready
echo "Waiting for deployments to be ready..."
kubectl rollout status deployment/mcp-neo4j-cypher -n neo4j
kubectl rollout status deployment/mcp-neo4j-memory -n neo4j
kubectl rollout status deployment/mcp-neo4j-data-modeling -n neo4j

# Get service endpoints
echo ""
echo "Services deployed successfully!"
echo ""
echo "Service endpoints:"
kubectl get services -n neo4j -l project=mcp-neo4j

# Get ingress information
echo ""
echo "Ingress information:"
kubectl get ingress -n neo4j

echo ""
echo "Deployment complete!"
echo ""
echo "Note: Update the ingress domain name and create a static IP before production use."