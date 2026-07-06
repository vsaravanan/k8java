#!/bin/bash

set -exuo pipefail

# Variables
PROJECT_DIR=/data/java/Hello
BUILD_DIR=/data/java/k8java
REGISTRY="k8master:5000"
IMAGE_NAME="hello-api:latest"
FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}"

cd $PROJECT_DIR

git reset --hard
git pull

cd $BUILD_DIR

git reset --hard
git pull
chmod +x *.sh

# Prepare k8master directories
lxc exec k8master -- mkdir -p "${PROJECT_DIR}" "${BUILD_DIR}"

# Copy source code, Dockerfile, and build script to k8master
echo "Copying files to k8master..."
lxc file push ${PROJECT_DIR} "k8master${PROJECT_DIR}/"
lxc file push ${BUILD_DIR}/Dockerfile "k8master${BUILD_DIR}/"
lxc file push ${BUILD_DIR}/k8master-build.sh "k8master${BUILD_DIR}/"

# Execute build script on k8master
echo "Executing build on k8master..."
lxc exec k8master -- bash ${BUILD_DIR}/k8master-build.sh

echo "Image built and pushed: ${FULL_IMAGE_NAME}"
