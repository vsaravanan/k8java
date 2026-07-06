#!/bin/bash

set -exuo pipefail

# Variables
PROJECT_DIR=/data/java/Hello
BUILD_DIR=/data/java/k8java
REGISTRY="k8master:5000"
IMAGE_NAME="hello-api:latest"
FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}"


# Build JAR
cd ${PROJECT_DIR}
echo "Maven building JAR..."
mvn clean package

# Build image
cd ${BUILD_DIR}
echo "Building OCI image..."
buildah bud -f Dockerfile -t ${FULL_IMAGE_NAME} .

# Push to registry
echo "Pushing image to registry..."
buildah push --tls-verify=false docker://${FULL_IMAGE_NAME}

echo "Image built and pushed: ${FULL_IMAGE_NAME}"
