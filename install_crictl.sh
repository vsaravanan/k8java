#!/bin/bash

set -exuo pipefail

# Define the version matching your Kubernetes setup (e.g., v1.30.0)
VERSION="v1.36.0"

# Download the tarball archive
curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-${VERSION}-linux-amd64.tar.gz --output crictl-${VERSION}-linux-amd64.tar.gz

# Extract the binary into your local system path
sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin

# Clean up the downloaded archive
rm -f crictl-$VERSION-linux-amd64.tar.gz
