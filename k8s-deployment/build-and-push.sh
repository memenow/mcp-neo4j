#!/bin/bash

# 设置镜像仓库前缀
REGISTRY="your-registry"  # 请替换为您的镜像仓库地址
TAG="${1:-latest}"

# 构建并推送各个服务的Docker镜像
echo "Building and pushing MCP Neo4j services..."

# 构建mcp-neo4j-cypher
echo "Building mcp-neo4j-cypher..."
cd ../servers/mcp-neo4j-cypher
docker build -t ${REGISTRY}/mcp-neo4j-cypher:${TAG} .
docker push ${REGISTRY}/mcp-neo4j-cypher:${TAG}

# 构建mcp-neo4j-memory
echo "Building mcp-neo4j-memory..."
cd ../mcp-neo4j-memory
docker build -t ${REGISTRY}/mcp-neo4j-memory:${TAG} .
docker push ${REGISTRY}/mcp-neo4j-memory:${TAG}

# 构建mcp-neo4j-aura-manager
echo "Building mcp-neo4j-aura-manager..."
cd ../mcp-neo4j-cloud-aura-api
docker build -t ${REGISTRY}/mcp-neo4j-aura-manager:${TAG} .
docker push ${REGISTRY}/mcp-neo4j-aura-manager:${TAG}

# 构建mcp-neo4j-data-modeling
echo "Building mcp-neo4j-data-modeling..."
cd ../mcp-neo4j-data-modeling
docker build -t ${REGISTRY}/mcp-neo4j-data-modeling:${TAG} .
docker push ${REGISTRY}/mcp-neo4j-data-modeling:${TAG}

echo "All images built and pushed successfully!"