FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV container docker

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y \
    systemd \
    systemd-sysv \
    init \
    dbus \
    git \
    curl \
    jq \
    make \
    python3 \
    python3-pip \
    vim \
    nano \
    bash-completion \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Minimal pipeline runner: executes stages defined in a simple YAML-like format
RUN mkdir -p /opt/lab
COPY pipeline-runner.sh /opt/lab/pipeline
RUN chmod +x /opt/lab/pipeline

# Simple Jenkinsfile runner wrapper (validates Groovy declarative syntax)
COPY jenkinsfile-runner.sh /opt/lab/run-jenkinsfile
RUN chmod +x /opt/lab/run-jenkinsfile

# Pre-populate the workspace with lab files
RUN mkdir -p /workspace/artifacts /workspace/src

# Disable systemd units that don't work in containers
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do \
        [ "$i" = "systemd-tmpfiles-setup.service" ] || rm -f "$i"; done) && \
    find /lib/systemd/system/multi-user.target.wants/ -maxdepth 1 \
      \( -name "*udev*" -o -name "*initctl*" -o -name "*getty*" -o -name "*plymouth*" \
         -o -name "*keyboard*" -o -name "*hwclock*" -o -name "*kmod*" \) \
      -exec rm -f {} \; && \
    rm -f /lib/systemd/system/local-fs.target.wants/* && \
    rm -f /lib/systemd/system/sockets.target.wants/*udev* && \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl* && \
    rm -f /lib/systemd/system/basic.target.wants/* && \
    rm -f /lib/systemd/system/anaconda.target.wants/* && \
    systemctl mask dev-hugepages.mount sys-kernel-debug.mount \
      sys-kernel-tracing.mount systemd-udevd.service

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
