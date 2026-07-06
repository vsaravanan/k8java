#!/bin/bash

set -exuo pipefail

# Variables
PROJECT_DIR=/data/java/Hello
BUILD_DIR=/data/java/k8java
REGISTRY="k8master:5000"
IMAGE_REPO="hello-api"



log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }
fail() { printf '\n\033[1;31mFAILED: %s\033[0m\n' "$1" >&2; exit 1; }

BUILD_TAG="$(date +%Y%m%d-%H%M%S)-$(git -C "${PROJECT_DIR}" rev-parse --short HEAD 2>/dev/null || echo nogit)"
IMAGE_LATEST="${REGISTRY}/${IMAGE_REPO}:latest"
IMAGE_TAGGED="${REGISTRY}/${IMAGE_REPO}:${BUILD_TAG}"

 
START_TIME=$(date +%s)
log "Starting build at $START_TIME"

# Build JAR
log "Maven building JAR..."

cd ${PROJECT_DIR}
mvn clean package

# Build image
log "Building OCI image..."

cd ${PROJECT_DIR}
buildah bud \
    -f "${BUILD_DIR}/Dockerfile" \
    -t "${IMAGE_TAGGED}" \
    -t "${IMAGE_LATEST}" \
    "${PROJECT_DIR}"

# Push to registry

log "Pushing ${IMAGE_TAGGED} to registry..."
buildah push --tls-verify=false \
    "${IMAGE_TAGGED}" "docker://${IMAGE_TAGGED}"
 
log "Pushing ${IMAGE_LATEST} to registry..."
buildah push --tls-verify=false \
    "${IMAGE_LATEST}" "docker://${IMAGE_LATEST}"

log "Verifying registry contents"
if lxc exec "${NODE}" -- curl -sf "http://${REGISTRY}/v2/${IMAGE_REPO}/tags/list" \
    | grep -q "${BUILD_TAG}"; then
  log "Confirmed: ${BUILD_TAG} present in registry"
else
  fail "push reported success but ${BUILD_TAG} not found in registry tag list"
fi

ELAPSED=$(( $(date +%s) - START_TIME ))
log "Build job completed in ${ELAPSED} seconds"

log "Image built and pushed: ${IMAGE_TAGGED}"

log "  Image (versioned): ${IMAGE_TAGGED}"
log "  Image (latest):    ${IMAGE_LATEST}"
log
log "To roll this out to a running Deployment:"
log "  kubectl set image deployment/hello-api hello-api=${IMAGE_TAGGED}"
log "  kubectl rollout status deployment/hello-api"
