FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV container docker

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install systemd and base tools
RUN apt-get update && apt-get install -y \
    systemd \
    systemd-sysv \
    init \
    dbus \
    curl \
    wget \
    gnupg \
    software-properties-common \
    lsb-release \
    vim \
    nano \
    jq \
    ca-certificates \
    prometheus \
    prometheus-node-exporter \
    && rm -rf /var/lib/apt/lists/*

# Install Grafana via official apt repo
RUN wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key && \
    echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" \
      > /etc/apt/sources.list.d/grafana.list && \
    apt-get update && apt-get install -y grafana && \
    rm -rf /var/lib/apt/lists/*

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
    rm -f /lib/systemd/system/anaconda.target.wants/* && \
    systemctl mask dev-hugepages.mount sys-kernel-debug.mount \
      sys-kernel-tracing.mount systemd-udevd.service

# Write a clean default prometheus.yml
RUN mkdir -p /etc/prometheus /var/lib/prometheus /etc/prometheus/rules && \
    cat > /etc/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - /etc/prometheus/rules/*.yml

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['localhost:9090']

  - job_name: node
    static_configs:
      - targets: ['localhost:9100']
EOF

# Grafana provisioning directory for datasources
RUN mkdir -p /etc/grafana/provisioning/datasources && \
    cat > /etc/grafana/provisioning/datasources/prometheus.yaml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
    editable: true
EOF

# Set Grafana admin password to 'admin' (disable change-on-login prompt)
RUN sed -i 's/;admin_password = admin/admin_password = admin/' /etc/grafana/grafana.ini && \
    echo -e '\n[security]\nadmin_password = admin\nadmin_user = admin' >> /etc/grafana/grafana.ini

# Fix prometheus data dir ownership (ubuntu apt installs prometheus user)
RUN chown -R prometheus:prometheus /var/lib/prometheus /etc/prometheus || true

# Enable services
RUN systemctl enable prometheus prometheus-node-exporter grafana-server

STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init"]
