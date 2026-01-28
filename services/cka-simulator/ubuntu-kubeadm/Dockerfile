# Ubuntu 22.04 with Kubernetes tools for CKA practice
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    systemd \
    systemd-sysv \
    init \
    wget \
    vim \
    nano \
    net-tools \
    iputils-ping \
    dnsutils \
    htop \
    tree \
    jq \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io \
    && rm -rf /var/lib/apt/lists/*

# Configure containerd
RUN mkdir -p /etc/containerd \
    && containerd config default | tee /etc/containerd/config.toml \
    && sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Install Kubernetes tools
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /usr/share/keyrings/kubernetes-apt-keyring.gpg \
    && echo 'deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update \
    && apt-get install -y kubelet=1.28.2-1.1 kubeadm=1.28.2-1.1 kubectl=1.28.2-1.1 \
    && apt-mark hold kubelet kubeadm kubectl \
    && rm -rf /var/lib/apt/lists/*

# Install Helm
RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list \
    && apt-get update \
    && apt-get install -y helm \
    && rm -rf /var/lib/apt/lists/*

# Install additional tools commonly used in CKA
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# Install etcdctl
RUN ETCD_VER=v3.5.9 \
    && curl -L https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz \
    && tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp \
    && mv /tmp/etcd-${ETCD_VER}-linux-amd64/etcdctl /usr/local/bin/ \
    && rm -rf /tmp/etcd-*

# Configure systemd
RUN systemctl enable docker \
    && systemctl enable containerd \
    && systemctl enable kubelet

# Create kubernetes user
RUN useradd -m -s /bin/bash kubernetes \
    && usermod -aG docker kubernetes \
    && usermod -aG sudo kubernetes \
    && echo "kubernetes ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up kubectl completion and aliases
RUN echo 'source <(kubectl completion bash)' >> /home/kubernetes/.bashrc \
    && echo 'alias k=kubectl' >> /home/kubernetes/.bashrc \
    && echo 'complete -F __start_kubectl k' >> /home/kubernetes/.bashrc \
    && echo 'export KUBECONFIG=/home/kubernetes/.kube/config' >> /home/kubernetes/.bashrc

# Create .kube directory
RUN mkdir -p /home/kubernetes/.kube \
    && chown -R kubernetes:kubernetes /home/kubernetes/.kube

# Copy initialization scripts
COPY scripts/ /opt/cka-scripts/
RUN chmod +x /opt/cka-scripts/*.sh

# Configure kernel parameters for Kubernetes
RUN echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf \
    && echo 'net.bridge.bridge-nf-call-ip6tables = 1' >> /etc/sysctl.conf \
    && echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf

# Disable swap (required for Kubernetes)
RUN swapoff -a \
    && sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Set working directory
WORKDIR /home/kubernetes

# Switch to kubernetes user
USER kubernetes

# Expose common Kubernetes ports
EXPOSE 6443 2379 2380 10250 10251 10252 10255

# Start systemd
CMD ["/sbin/init"]