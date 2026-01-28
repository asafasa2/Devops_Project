#!/bin/bash
# Initialize Kubernetes master node for CKA practice

set -e

echo "Initializing Kubernetes master node..."

# Start required services
sudo systemctl start docker
sudo systemctl start containerd

# Initialize the cluster
sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --service-cidr=10.96.0.0/12 \
  --apiserver-advertise-address=$(hostname -I | awk '{print $1}') \
  --ignore-preflight-errors=all

# Set up kubectl for the kubernetes user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico CNI
echo "Installing Calico CNI..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml

# Wait for operator to be ready
kubectl wait --for=condition=Ready pod -l name=tigera-operator -n tigera-operator --timeout=300s

# Apply Calico configuration
cat <<EOF | kubectl apply -f -
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
    - blockSize: 26
      cidr: 192.168.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
---
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
EOF

# Wait for all system pods to be ready
echo "Waiting for system pods to be ready..."
kubectl wait --for=condition=Ready pod --all -n kube-system --timeout=600s

# Generate join command for worker nodes
JOIN_COMMAND=$(sudo kubeadm token create --print-join-command)
echo "Join command for worker nodes:"
echo "$JOIN_COMMAND"
echo "$JOIN_COMMAND" > /tmp/join-command.sh

# Enable kubectl completion
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc

echo "Master node initialization complete!"
echo "Cluster status:"
kubectl get nodes
kubectl get pods -A