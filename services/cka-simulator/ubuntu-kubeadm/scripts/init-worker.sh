#!/bin/bash
# Initialize Kubernetes worker node for CKA practice

set -e

echo "🚀 Initializing Kubernetes worker node..."

# Ensure we're running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Start required services
echo "📋 Starting required services..."
systemctl start docker
systemctl start containerd
systemctl start ssh

# Wait for services to be ready
sleep 5

# Load kernel modules
echo "🔧 Loading kernel modules..."
modprobe br_netfilter
modprobe overlay

# Apply sysctl settings
echo "⚙️  Applying sysctl settings..."
sysctl --system

# Wait for join command from master
echo "⏳ Waiting for join command from master node..."
TIMEOUT=300
COUNTER=0

while [ ! -f /tmp/join-command.sh ] && [ $COUNTER -lt $TIMEOUT ]; do
    echo "Waiting for join command... ($COUNTER/$TIMEOUT)"
    sleep 5
    COUNTER=$((COUNTER + 5))
done

if [ ! -f /tmp/join-command.sh ]; then
    echo "❌ Timeout waiting for join command from master"
    echo "🔧 Attempting to join with default settings..."
    
    # Try to discover master node and join
    MASTER_IP=$(getent hosts master | awk '{print $1}' || echo "172.28.0.2")
    echo "🌐 Attempting to join master at $MASTER_IP"
    
    # This would normally fail without proper token, but shows the attempt
    echo "⚠️  Manual join required - check master node for join command"
    exit 1
fi

# Execute join command
echo "🔗 Joining the cluster..."
chmod +x /tmp/join-command.sh
bash /tmp/join-command.sh

# Wait a moment for the node to register
sleep 10

# Set up kubectl for kubernetes user (copy from master if available)
echo "🔑 Setting up kubectl access..."
if [ -f /etc/kubernetes/kubelet.conf ]; then
    mkdir -p /home/kubernetes/.kube
    cp /etc/kubernetes/kubelet.conf /home/kubernetes/.kube/config
    chown kubernetes:kubernetes /home/kubernetes/.kube/config
fi

# Enable kubectl completion
echo "🔧 Setting up kubectl completion..."
echo 'source <(kubectl completion bash)' >> /home/kubernetes/.bashrc
echo 'alias k=kubectl' >> /home/kubernetes/.bashrc
echo 'complete -F __start_kubectl k' >> /home/kubernetes/.bashrc

echo "✅ Worker node initialization complete!"
echo "🎯 Node should appear in cluster shortly..."
echo ""
echo "🔍 To verify from master node, run:"
echo "   kubectl get nodes"