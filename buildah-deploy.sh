#!/bin/bash

set -exuo pipefail

git reset --hard; git pull ; chmod +x *.sh ; 

# Variables
PROJECT_DIR=/data/java/Hello
BUILD_DIR=/data/java/k8java
JAR_FILE="${PROJECT_DIR}/target/Hello.jar"
REGISTRY="k8master:5000"
IMAGE_NAME="hello-api:latest"
FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}"

cd ${PROJECT_DIR}

echo "Maven building JAR..."
mvn clean package

cd ${BUILD_DIR}

echo "Building OCI image..."
lxc exec k8master -- buildah bud \
    -t ${FULL_IMAGE_NAME} \
    -v ${PROJECT_DIR}/target:/workspace/target:ro \
    .

echo "Pushing image..."
lxc exec k8master -- buildah push \
    --tls-verify=false \
    docker://${FULL_IMAGE_NAME}

echo "Image built and pushed: ${FULL_IMAGE_NAME}"
