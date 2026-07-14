FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Tools for Option 1 in-container egress control:
#   dnsmasq  - domain allow-list resolver
#   iptables - packet-level DNS bypass prevention
RUN apt-get update && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        dnsmasq iptables ipset dnsutils ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install latest Python and Node.js
RUN apt-get update && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        python3 python3-pip python3-venv \
        nodejs npm && \
    rm -rf /var/lib/apt/lists/*

# Verify installations
RUN python3 --version && node --version && npm --version
