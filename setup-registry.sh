#!/bin/bash

# Create registry directory
mkdir -p /data/registry

# Run Docker Registry container
docker run -d \
  --name registry \
  --restart=always \
  -p 5000:5000 \
  -v /data/registry:/var/lib/registry \
  registry:2

echo "Registry started on port 5000"
echo "Registry data stored in /data/registry"
