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
    nginx \
    curl \
    vim \
    nano \
    iproute2 \
    net-tools \
    iputils-ping \
    bash-completion \
    sudo \
    acl \
    e2fsprogs \
    parted \
    lvm2 \
    procps \
    htop \
    cron \
    at \
    passwd \
    adduser \
    && rm -rf /var/lib/apt/lists/*

# Remove systemd services that don't work in containers.
# Use targeted removal to avoid nuking all multi-user wants (which would break nginx).
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

RUN systemctl enable nginx

STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init"]
