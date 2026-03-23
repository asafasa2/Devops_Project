#!/bin/bash
# Initialize Kubernetes master node for CKA practice

set -e

echo "🚀 Initializing Kubernetes master node..."

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

# Get the node IP address
NODE_IP=$(hostname -I | awk '{print $1}')
echo "🌐 Node IP: $NODE_IP"

# Initialize the cluster with specific configuration
echo "🎯 Initializing Kubernetes cluster..."
kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --service-cidr=10.96.0.0/12 \
  --apiserver-advertise-address=$NODE_IP \
  --apiserver-cert-extra-sans=$NODE_IP,localhost,127.0.0.1 \
  --node-name=$(hostname) \
  --ignore-preflight-errors=all \
  --skip-phases=addon/kube-proxy

# Set up kubectl for root user
echo "🔑 Setting up kubectl for root user..."
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown root:root /root/.kube/config

# Set up kubectl for kubernetes user
echo "🔑 Setting up kubectl for kubernetes user..."
mkdir -p /home/kubernetes/.kube
cp -i /etc/kubernetes/admin.conf /home/kubernetes/.kube/config
chown kubernetes:kubernetes /home/kubernetes/.kube/config

# Install Calico CNI
echo "🌐 Installing Calico CNI..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml

# Wait for operator to be ready
echo "⏳ Waiting for Tigera operator..."
kubectl wait --for=condition=Ready pod -l name=tigera-operator -n tigera-operator --timeout=300s

# Apply Calico configuration
echo "🔧 Configuring Calico..."
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

# Install kube-proxy manually
echo "🔧 Installing kube-proxy..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/kubernetes/v1.28.2/cluster/addons/kube-proxy/kube-proxy-daemonset.yaml

# Wait for all system pods to be ready
echo "⏳ Waiting for system pods to be ready..."
kubectl wait --for=condition=Ready pod --all -n kube-system --timeout=600s || true

# Remove taint from master node to allow scheduling
echo "🏷️  Removing master node taint..."
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true
kubectl taint nodes --all node-role.kubernetes.io/master- || true

# Generate join command for worker nodes
echo "🔗 Generating join command for worker nodes..."
JOIN_COMMAND=$(kubeadm token create --print-join-command)
echo "Join command for worker nodes:"
echo "$JOIN_COMMAND"
echo "$JOIN_COMMAND" > /tmp/join-command.sh
chmod +x /tmp/join-command.sh

# Create some sample resources for CKA practice
echo "📝 Creating sample resources for CKA practice..."

# Create namespaces
kubectl create namespace production || true
kubectl create namespace development || true
kubectl create namespace testing || true

# Create a sample deployment
kubectl create deployment nginx-deployment --image=nginx:1.20 --replicas=3 -n production || true

# Create a sample service
kubectl expose deployment nginx-deployment --port=80 --target-port=80 --type=ClusterIP -n production || true

# Create a sample configmap
kubectl create configmap app-config --from-literal=database_url=postgresql://localhost:5432/app -n production || true

# Create a sample secret
kubectl create secret generic app-secret --from-literal=api_key=super-secret-key -n production || true

# Enable kubectl completion
echo "🔧 Setting up kubectl completion..."
echo 'source <(kubectl completion bash)' >> /root/.bashrc
echo 'alias k=kubectl' >> /root/.bashrc
echo 'complete -F __start_kubectl k' >> /root/.bashrc

echo 'source <(kubectl completion bash)' >> /home/kubernetes/.bashrc
echo 'alias k=kubectl' >> /home/kubernetes/.bashrc
echo 'complete -F __start_kubectl k' >> /home/kubernetes/.bashrc

# Create CKA exam directory structure
echo "📁 Creating CKA exam directory structure..."
for i in {1..17}; do
    mkdir -p /opt/course/$i
    chown kubernetes:kubernetes /opt/course/$i
done

# Create sample kubeconfig for task 1
echo "📄 Creating sample kubeconfig for CKA tasks..."
cat > /opt/course/1/kubeconfig <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTi...
    server: https://127.0.0.1:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
- context:
    cluster: kubernetes
    user: account-0027
  name: account-0027@kubernetes
- context:
    cluster: kubernetes
    user: system:node:worker1
  name: system:node:worker1@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: LS0tLS1CRUdJTi...
    client-key-data: LS0tLS1CRUdJTi...
- name: account-0027
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURJVENDQWdtZ0F3SUJBZ0lJTnNkSGFBWVBHVGt3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TkRBeE1qZ3hNekEwTURCYUZ3MHlOVEF4TWpneE16QTBNREJhTURReApGekFWQmdOVkJBb1REbk41YzNSbGJUcHRZWE4wWlhKek1Sa3dGd1lEVlFRREV4QnJkV0psY201bGRHVnpMV0ZrCmJXbHVNSUlCSWpBTkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQXNxVGhOVGhxVGhOVGhxVGgKTlRocVRoTlRocVRoTlRocVRoTlRocVRoTlRocVRoTlRocVRoTlRocVRoTlRocVRoTlRocVRoTlRocVRoTlRocQpUaE5UaHFUaE5UaHFUaE5UaHFUaE5UaHFUaE5UaHFUaE5UaHFUaE5UaHFUaE5UaHFUaE5UaHFUaE5UaHFUaE5UCmhxVGhOVGhxVGhOVGhxVGhOVGhxVGhOVGhxVGhOVGhxVGhOVGhxVGhOVGhxVGhOVGhxVGhOVGhxVGhOVGhxVGgKTlRocVRoTlRocVRoTlRocVRoTlRocVRoTlRocVRoTlRocVRoTlRocVRoTlRocVRoTlRocVRoTlRocVRoTlRocQpUaE5UaHFUaE5UaHFUaE5UaHFUaE5UaHFUaE5UaHFUaE5UaHFUaE5UaHFUaE5UaHFUaE5UaHFUaE5UaHFUaE5UCmhxVGhOVGhxVGhOVGhxVGhOVGhxVGhOVGhxVGhOVGhxVGhOVGhxVGhOVGhxVGhOVGhxVGhOVGhxVGhOVGhxVGgKTlJJREFRQUJvMUl3VURBT0JnTlZIUThCQWY4RUJBTUNCYUF3RXdZRFZSMGxCQXd3Q2dZSUt3WUJCUVVIQXdJdwpEQVlEVlIwVEFRSC9CQUl3QURBZkJnTlZIU01FR0RBV2dCUXNxVGhOVGhxVGhOVGhxVGhOVGhxVGhOVGhxVGgKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
    client-key-data: LS0tLS1CRUdJTi...
- name: system:node:worker1
  user:
    client-certificate-data: LS0tLS1CRUdJTi...
    client-key-data: LS0tLS1CRUdJTi...
EOF

chown kubernetes:kubernetes /opt/course/1/kubeconfig

echo "✅ Master node initialization complete!"
echo ""
echo "📊 Cluster status:"
kubectl get nodes -o wide
echo ""
echo "🏃 System pods:"
kubectl get pods -A
echo ""
echo "🔗 Join command saved to /tmp/join-command.sh"
echo "🎯 CKA exam directories created in /opt/course/"
echo ""
echo "🚀 Master node is ready for CKA practice!"