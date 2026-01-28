#!/bin/bash
# Build the Ubuntu image with Kubernetes tools for CKA simulator

set -e

echo "Building CKA Ubuntu image with Kubernetes tools..."

# Build the image
docker build -t cka-ubuntu:latest ./ubuntu-kubeadm/

echo "CKA Ubuntu image built successfully!"
echo "Image: cka-ubuntu:latest"

# Show image details
docker images cka-ubuntu:latest