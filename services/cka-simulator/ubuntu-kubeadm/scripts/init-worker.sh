#!/bin/bash
# Initialize Kubernetes worker node for CKA practice

set -e

echo "Initializing Kubernetes worker node..."

# Start required services
sudo systemctl start docker
sudo systemctl start containerd

# Wait for join command from master
echo "Waiting for join command from master node..."
while [ ! -f /tmp/join-command.sh ]; do
  sleep 5
done

# Execute join command
echo "Joining the cluster..."
sudo bash /tmp/join-command.sh

echo "Worker node initialization complete!"
echo "Node should appear in cluster shortly..."