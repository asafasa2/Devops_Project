FROM devops-lab/base-linux:latest

# Security hardening tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    nftables \
    auditd \
    audispd-plugins \
    aide \
    fail2ban \
    libpam-pwquality \
    && rm -rf /var/lib/apt/lists/*

# Configure SSH for lab use
RUN mkdir -p /run/sshd \
    && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

# Create a test user with a weak password (for hardening labs)
RUN useradd -m -s /bin/bash labuser \
    && echo 'labuser:password123' | chpasswd \
    && echo 'root:rootpass' | chpasswd

# Enable services
RUN systemctl enable ssh || true

EXPOSE 22 80 443
