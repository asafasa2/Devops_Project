# Ubuntu 22.04 with Kubernetes tools for CKA practice
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set timezone
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

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
    openssh-server \
    sudo \
    iproute2 \
    iptables \
    bridge-utils \
    socat \
    conntrack \
    ipset \
    ethtool \
    util-linux \
    mount \
    tar \
    unzip \
    bash-completion \
    && rm -rf /var/lib/apt/lists/*

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Configure containerd for Kubernetes
RUN mkdir -p /etc/containerd \
    && containerd config default | tee /etc/containerd/config.toml \
    && sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml \
    && sed -i 's/sandbox_image = "registry.k8s.io\/pause:3.6"/sandbox_image = "registry.k8s.io\/pause:3.9"/' /etc/containerd/config.toml

# Install Kubernetes tools (v1.28 - current CKA exam version)
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /usr/share/keyrings/kubernetes-apt-keyring.gpg \
    && echo 'deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update \
    && apt-get install -y kubelet=1.28.2-1.1 kubeadm=1.28.2-1.1 kubectl=1.28.2-1.1 \
    && apt-mark hold kubelet kubeadm kubectl \
    && rm -rf /var/lib/apt/lists/*

# Install crictl (Container Runtime Interface CLI)
RUN VERSION="v1.28.0" \
    && curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz" | tar -C /usr/local/bin -xz

# Install Helm (simplified)
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    && chmod 700 get_helm.sh \
    && ./get_helm.sh \
    && rm get_helm.sh

# Install etcdctl
RUN ETCD_VER=v3.5.9 \
    && curl -L https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz \
    && tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp \
    && mv /tmp/etcd-${ETCD_VER}-linux-amd64/etcdctl /usr/local/bin/ \
    && rm -rf /tmp/etcd-*

# Install additional CKA exam tools
RUN curl -LO "https://dl.k8s.io/release/v1.28.2/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# Install yq for YAML processing
RUN curl -L "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# Configure systemd services
RUN systemctl enable docker \
    && systemctl enable containerd \
    && systemctl enable kubelet \
    && systemctl enable ssh

# Create kubernetes user with sudo privileges
RUN useradd -m -s /bin/bash kubernetes \
    && usermod -aG docker kubernetes \
    && usermod -aG sudo kubernetes \
    && echo "kubernetes ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && echo "kubernetes:kubernetes" | chpasswd

# Set up kubectl completion and aliases for kubernetes user
RUN echo 'source <(kubectl completion bash)' >> /home/kubernetes/.bashrc \
    && echo 'alias k=kubectl' >> /home/kubernetes/.bashrc \
    && echo 'complete -F __start_kubectl k' >> /home/kubernetes/.bashrc \
    && echo 'export KUBECONFIG=/home/kubernetes/.kube/config' >> /home/kubernetes/.bashrc \
    && echo 'export ETCDCTL_API=3' >> /home/kubernetes/.bashrc \
    && echo 'export PATH=$PATH:/usr/local/bin' >> /home/kubernetes/.bashrc

# Set up kubectl completion and aliases for root user
RUN echo 'source <(kubectl completion bash)' >> /root/.bashrc \
    && echo 'alias k=kubectl' >> /root/.bashrc \
    && echo 'complete -F __start_kubectl k' >> /root/.bashrc \
    && echo 'export KUBECONFIG=/root/.kube/config' >> /root/.bashrc \
    && echo 'export ETCDCTL_API=3' >> /root/.bashrc \
    && echo 'export PATH=$PATH:/usr/local/bin' >> /root/.bashrc

# Create .kube directories
RUN mkdir -p /home/kubernetes/.kube /root/.kube \
    && chown -R kubernetes:kubernetes /home/kubernetes/.kube

# Configure kernel parameters for Kubernetes
RUN echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf \
    && echo 'net.bridge.bridge-nf-call-ip6tables = 1' >> /etc/sysctl.conf \
    && echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf

# Load br_netfilter module
RUN echo 'br_netfilter' >> /etc/modules-load.d/k8s.conf \
    && echo 'overlay' >> /etc/modules-load.d/k8s.conf

# Disable swap (required for Kubernetes) - handle gracefully in container
RUN swapoff -a || true \
    && sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab || true

# Configure SSH for remote access
RUN mkdir -p /var/run/sshd \
    && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config \
    && echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config

# Set root password
RUN echo "root:root" | chpasswd

# Copy initialization scripts
COPY scripts/ /opt/cka-scripts/
RUN chmod +x /opt/cka-scripts/*.sh

# Create exam directories structure
RUN mkdir -p /opt/course/{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17} \
    && mkdir -p /etc/kubernetes/manifests \
    && mkdir -p /var/lib/etcd \
    && chown -R kubernetes:kubernetes /opt/course

# Set working directory
WORKDIR /root

# Expose common Kubernetes and SSH ports
EXPOSE 6443 2379 2380 10250 10251 10252 10255 22

# Create entrypoint script
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'set -e' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Start systemd services' >> /entrypoint.sh && \
    echo 'systemctl start ssh' >> /entrypoint.sh && \
    echo 'systemctl start docker' >> /entrypoint.sh && \
    echo 'systemctl start containerd' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Load kernel modules' >> /entrypoint.sh && \
    echo 'modprobe br_netfilter' >> /entrypoint.sh && \
    echo 'modprobe overlay' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Apply sysctl settings' >> /entrypoint.sh && \
    echo 'sysctl --system' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Keep container running' >> /entrypoint.sh && \
    echo 'exec "$@"' >> /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/sbin/init"]