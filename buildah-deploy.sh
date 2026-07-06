#!/bin/bash

# Variables
JAR_FILE="/data/java/Hello/target/Hello.jar"
REGISTRY="k8master:5000"
IMAGE_NAME="hello-api:buildah"
FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}":latest

cd /data/java/Hello

echo "Building JAR..."
mvn clean package

echo "Building OCI image..."
buildah bud \
    -t ${FULL_IMAGE_NAME} \
    .

echo "Pushing image..."
buildah push \
    --tls-verify=false \
    docker://${FULL_IMAGE_NAME}

echo "Image built and pushed: ${FULL_IMAGE_NAME}"
