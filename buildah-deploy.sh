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


# buildah bud -t k8master:5000/hello-api:latest .

# buildah bud \
#     -f /data/java/k8java/Dockerfile \
#     -t k8master:5000/hello-api:latest \
#     /data/Hello

lxc exec k8master -- mkdir -p "$BUILD_DIR/target/"

read -p "Enter"

lxc file push "$JAR_FILE" k8master/$BUILD_DIR/target/

read -p "Enter"

lxc file push "$BUILD_DIR/Dockerfile" k8master/$BUILD_DIR/

read -p "Enter"


echo "Building OCI image..."
# lxc exec k8master -- buildah bud \
#     -t ${FULL_IMAGE_NAME} \
#     -v ${PROJECT_DIR}/target:/workspace/target:ro \
#     .

lxc exec k8master -- buildah bud \
    -f ${BUILD_DIR}/Dockerfile \
    -t ${FULL_IMAGE_NAME} \
    ${BUILD_DIR}

read -p "Enter"


echo "Pushing image..."
lxc exec k8master -- buildah push \
    --tls-verify=false \
    docker://${FULL_IMAGE_NAME}

echo "Image built and pushed: ${FULL_IMAGE_NAME}"
