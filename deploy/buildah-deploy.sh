#!/bin/bash

set -exuo pipefail

# Variables
# PROJECT_DIR=/data/java/Hello
# BUILD_DIR=/data/java/k8java
# REGISTRY="k8master:5000"
# IMAGE_NAME="hello-api:latest"
# FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}"

copy_dir() {
    local Origin="$1"
    local Project="$2"
    local SRC="$Origin/$Project"
    local DEST="${NODE}$Origin/$Project"
    local gzfile="$Origin/${Project}.tar.gz"

    cd "$Origin"

    rm -rf $gzfile $SRC/target

    log "Copying $gzfile to ${NODE}..."

    tar -czf $gzfile -C $Origin $Project

    sleep 2

    lxc exec ${NODE} -- bash -c "mkdir -p '$DEST' && tar -xzf $gzfile  -C '$DEST'"

}

ORIGIN_DIR="${ORIGIN_DIR:-/data/java}"
PROJECT_DIR="${PROJECT_DIR:-/data/java/Hello}"
BUILD_DIR="${BUILD_DIR:-/data/java/k8java/deploy}"
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
lxc exec "${NODE}" -- buildah >/dev/null || fail "buildah not found inside ${NODE}"

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
log "Copying files to ${NODE}..."


# copy_dir "${PROJECT_DIR}" "${NODE}${PROJECT_DIR}/" Hello
# copy_dir "${BUILD_DIR}" "${NODE}${BUILD_DIR}/" k8java

copy_dir "${ORIGIN_DIR}" Hello
exit 0
# copy_dir "${ORIGIN_DIR}" k8java


for arg in "$@"; do
    case "$arg" in
        registry)
            log "Applying registry..."
            lxc exec "${NODE}" -- kubectl apply -f "${NODE}${BUILD_DIR}/registry.yaml"
            sleep 5
            ;;
        hello-deploy)
            log "Applying hello-deploy..."
            lxc exec "${NODE}" -- kubectl apply -f "${NODE}${BUILD_DIR}/hello-deploy.yaml"

            log "Waiting for deployment..."

            lxc exec "${NODE}" --  kubectl rollout status deployment/hello-api --timeout=120s

            log "Deployment is ready."
            ;;
        *)
            log "Unknown argument: $arg"
            ;;
    esac
done





# Execute build script on ${NODE}
log "Executing build on ${NODE}..."
lxc exec "${NODE}" -- bash "${BUILD_DIR}/k8master-build.sh"

log "Image built and pushed"
