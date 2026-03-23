FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV container docker

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install systemd and base packages
RUN apt-get update && apt-get install -y \
    systemd \
    systemd-sysv \
    init \
    dbus \
    python3 \
    python3-pip \
    ansible \
    openssh-server \
    openssh-client \
    sshpass \
    vim \
    nano \
    jq \
    curl \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Trim systemd services that don't work in containers
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ "$i" = "systemd-tmpfiles-setup.service" ] || rm -f "$i"; done) && \
    find /lib/systemd/system/multi-user.target.wants/ -maxdepth 1 \
      \( -name "*udev*" -o -name "*initctl*" -o -name "*getty*" -o -name "*plymouth*" \
         -o -name "*keyboard*" -o -name "*hwclock*" -o -name "*kmod*" \
         -o -name "*blk-availability*" -o -name "*e2scrub*" \) \
      -exec rm -f {} \; && \
    rm -f /lib/systemd/system/local-fs.target.wants/* && \
    rm -f /lib/systemd/system/sockets.target.wants/*udev* && \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl* && \
    rm -f /lib/systemd/system/basic.target.wants/* && \
    rm -f /lib/systemd/system/anaconda.target.wants/*

# Configure sshd
RUN mkdir -p /var/run/sshd && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config && \
    systemctl enable ssh

# Generate SSH key pair for root (Ansible controller)
RUN mkdir -p /root/.ssh && \
    ssh-keygen -t rsa -b 2048 -N '' -f /root/.ssh/id_rsa && \
    chmod 700 /root/.ssh && \
    chmod 600 /root/.ssh/id_rsa

# Create ansible-target user with the generated public key
RUN useradd -m -s /bin/bash ansible-target && \
    echo 'ansible-target:ansible' | chpasswd && \
    mkdir -p /home/ansible-target/.ssh && \
    cp /root/.ssh/id_rsa.pub /home/ansible-target/.ssh/authorized_keys && \
    chmod 700 /home/ansible-target/.ssh && \
    chmod 600 /home/ansible-target/.ssh/authorized_keys && \
    chown -R ansible-target:ansible-target /home/ansible-target/.ssh && \
    echo 'ansible-target ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Pre-populate workspace and inventory
RUN mkdir -p /workspace
COPY inventory.ini /workspace/inventory.ini

# Disable host key checking for Ansible
RUN mkdir -p /etc/ansible && \
    printf '[defaults]\nhost_key_checking = False\nremote_user = root\n' > /etc/ansible/ansible.cfg

STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init"]
