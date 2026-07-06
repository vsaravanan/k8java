#!/bin/bash

# Install buildah
lxc exec k8master -- sudo apt install buildah

# Add user to subuid/subgid files (requires root)
sudo usermod --add-subuids 100000-165535 viswar
sudo usermod --add-subgids 100000-165535 viswar

# Push registry configuration to k8master via LXC
lxc file push ./registry.yaml k8master/root/registry.yaml

# Apply registry deployment
lxc exec k8master -- kubectl apply -f /root/registry.yaml

# Wait for registry pod to be ready
lxc exec k8master -- kubectl wait --for=condition=ready pod -l app=registry --timeout=300s

lxc exec k8master -- kubectl scale deployment registry --replicas=0
lxc exec k8master -- kubectl delete deployment registry --ignore-not-found
lxc exec k8master -- kubectl delete svc registry --ignore-not-found
lxc exec k8master -- kubectl delete rs -l app=registry --ignore-not-found
lxc exec k8master -- kubectl delete pods -l app=registry --force --grace-period=0 --ignore-not-found


lxc file push /data/java/k8java/hello-deploy.yaml k8master/root/hello-deploy.yaml
lxc exec k8master -- kubectl apply -f /root/hello-deploy.yaml