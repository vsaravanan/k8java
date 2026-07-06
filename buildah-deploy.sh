#!/bin/bash

# Variables
PROJECT_DIR=/data/java/Hello
BUILD_DIR=/data/k8java
JAR_FILE="${PROJECT_DIR}/target/Hello.jar"
REGISTRY="k8master:5000"
IMAGE_NAME="hello-api:buildah"
FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}:latest"

cd ${PROJECT_DIR}

echo "Maven building JAR..."
mvn clean package

cd ${BUILD_DIR}

echo "Building OCI image..."
buildah bud \
    -t ${FULL_IMAGE_NAME} \
    -v ${PROJECT_DIR}/target:/workspace/target:ro \
    .

echo "Pushing image..."
buildah push \
    --tls-verify=false \
    docker://${FULL_IMAGE_NAME}

echo "Image built and pushed: ${FULL_IMAGE_NAME}"
