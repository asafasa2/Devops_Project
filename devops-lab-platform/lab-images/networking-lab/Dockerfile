FROM devops-lab/base-linux:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    dnsutils \
    netcat-openbsd \
    tcpdump \
    nmap \
    iptables \
    nftables \
    openssl \
    traceroute \
    iproute2 \
    iputils-ping \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Enable IP forwarding for routing labs
RUN echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.d/99-lab.conf && \
    echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.d/99-lab.conf

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
