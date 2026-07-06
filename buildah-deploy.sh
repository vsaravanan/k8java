#!/bin/bash

set -exuo pipefail

# Variables
# PROJECT_DIR=/data/java/Hello
# BUILD_DIR=/data/java/k8java
# REGISTRY="k8master:5000"
# IMAGE_NAME="hello-api:latest"
# FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}"


PROJECT_DIR="${PROJECT_DIR:-/data/java/Hello}"
BUILD_DIR="${BUILD_DIR:-/data/java/k8java}"
REGISTRY="${REGISTRY:-k8master:5000}"
IMAGE_REPO="${IMAGE_REPO:-hello-api}"
NODE="${NODE:-k8master}"


log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }
fail() { printf '\n\033[1;31mFAILED: %s\033[0m\n' "$1" >&2; exit 1; }
 
START_TIME=$(date +%s)

log "Starting buildah deployment $START_TIME"

log "Preflight checks"
 
command -v lxc  >/dev/null || fail "lxc not found on PATH"
command -v mvn  >/dev/null || fail "mvn not found on PATH"

[[ -d "${PROJECT_DIR}" ]]            || fail "PROJECT_DIR does not exist: ${PROJECT_DIR}"
[[ -f "${BUILD_DIR}/Dockerfile" ]]   || fail "Dockerfile not found: ${BUILD_DIR}/Dockerfile"

lxc info "${NODE}" &>/dev/null       || fail "LXD container '${NODE}' not found/running"
lxc exec "${NODE}" -- command -v buildah >/dev/null || fail "buildah not found inside ${NODE}"

cd "${PROJECT_DIR}"

git -C "${PROJECT_DIR}" reset --hard
git -C "${PROJECT_DIR}" pull

cd "${BUILD_DIR}"

git -C "${BUILD_DIR}" reset --hard
git -C "${BUILD_DIR}" pull
chmod +x *.sh

# Prepare k8master directories
lxc exec "${NODE}" -- mkdir -p "${PROJECT_DIR}" "${BUILD_DIR}"

# Copy source code, Dockerfile, and build script to k8master
log "Copying files to k8master..."
lxc file push "${PROJECT_DIR}" "k8master${PROJECT_DIR}/"
lxc file push "${BUILD_DIR}/Dockerfile" "k8master${BUILD_DIR}/"
lxc file push "${BUILD_DIR}/k8master-build.sh" "k8master${BUILD_DIR}/"

# Execute build script on k8master
log "Executing build on k8master..."
lxc exec "${NODE}" -- bash "${BUILD_DIR}/k8master-build.sh"

log "Image built and pushed"
