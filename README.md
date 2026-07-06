# Java API Deployment Guide

This directory contains all files needed to deploy a simple Java API using both Buildah and Kaniko.

## Prerequisites
- Java 26 installed
- Maven installed
- Docker installed
- Buildah installed (for Buildah deployment)
- Kubernetes cluster (k8master)

## Directory Structure
```
d:\practice\java\k8java/
├── src/                     # Java source code
├── target/
│   └── Hello.jar            # Your built JAR file
├── Dockerfile               # Container image definition
├── buildah-deploy.sh        # Buildah deployment script
├── kaniko-deploy.yaml       # Kaniko job manifest
├── k8s-deployment.yaml      # Kubernetes deployment manifest
├── setup-registry.sh        # Docker registry setup script
└── registry-deployment.yaml # Kubernetes registry deployment
```

## Step 1: Build Your JAR File
```bash
# From the k8java project directory
cd d:\practice\java\k8java
mvn clean package

# Copy JAR to /data/target directory (for k8master)
mkdir -p /data/target
cp target/Hello.jar /data/target/Hello.jar
```

## Step 2: Copy Deployment Files to k8master
```bash
# Copy all deployment files to /data
cp Dockerfile /data/
cp buildah-deploy.sh /data/
cp kaniko-deploy.yaml /data/
cp k8s-deployment.yaml /data/
cp setup-registry.sh /data/
cp registry-deployment.yaml /data/
```

## Step 3: Setup Container Registry on k8master

### Option A: Docker Registry (Recommended - Simple)
```bash
chmod +x /data/setup-registry.sh
/data/setup-registry.sh

# Verify registry
docker ps | grep registry
curl http://localhost:5000/v2/_catalog
```

### Option B: Kubernetes Registry
```bash
mkdir -p /data/registry
kubectl apply -f /data/registry-deployment.yaml

# Get service URL
kubectl get svc registry
```

## Step 4: Deploy with Buildah (on k8master)

```bash
# Make script executable
chmod +x /data/buildah-deploy.sh

# Run deployment
/data/buildah-deploy.sh

# Verify image in registry
curl http://localhost:5000/v2/_catalog
curl http://localhost:5000/v2/hello-api/tags/list
```

## Step 5: Deploy with Kaniko (on k8master)

```bash
# Ensure Dockerfile and JAR are in /data
kubectl apply -f /data/kaniko-deploy.yaml

# Monitor job
kubectl get jobs
kubectl logs job/kaniko-build -f
```

## Step 6: Deploy Application to Kubernetes

### For Buildah Version
```bash
kubectl apply -f /data/k8s-deployment.yaml
```

### For Kaniko Version
```bash
# Update image tag
kubectl set image deployment/hello-api hello-api=k8master:5000/hello-api:kaniko
```

## Step 7: Test the API

```bash
# Check pods
kubectl get pods

# Get service details
kubectl get svc hello-api-service

# Port forward to test locally
kubectl port-forward svc/hello-api-service 8080:80

# Test endpoint
curl http://localhost:8080/hello
# Expected output: Hello, World!
```

## Alternative: Direct NodePort Access

```bash
# Get NodePort
kubectl get svc hello-api-service

# Access via NodePort
curl http://<node-ip>:<node-port>/hello
```

## Troubleshooting

### Registry Issues
```bash
# Check registry container
docker ps | grep registry
docker logs registry

# Restart registry
docker restart registry
```

### Buildah Issues
```bash
# Check Buildah installation
buildah --version

# List Buildah images
buildah images

# Clean up
buildah rm -a
buildah rmi -a
```

### Kaniko Issues
```bash
# Check job status
kubectl get jobs
kubectl describe job kaniko-build

# View logs
kubectl logs job/kaniko-build
```

### Kubernetes Issues
```bash
# Check pod status
kubectl get pods
kubectl describe pod <pod-name>

# View pod logs
kubectl logs <pod-name>

# Check events
kubectl get events
```

## Clean Up

```bash
# Delete Kubernetes resources
kubectl delete -f /data/k8s-deployment.yaml
kubectl delete -f /data/kaniko-deploy.yaml
kubectl delete -f /data/registry-deployment.yaml

# Stop Docker registry
docker stop registry
docker rm registry

# Clean registry data
rm -rf /data/registry
```
