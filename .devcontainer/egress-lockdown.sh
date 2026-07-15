#!/usr/bin/env bash
###############################################################################
# Option 1 - In-container egress control for GitHub Codespaces.
#   Layer 1: dnsmasq domain allow-list (see dnsmasq.conf)
#   Layer 2: iptables to force all DNS through dnsmasq and block DoH bypass
#   Layer 3: Allow HTTPS (443) for extension downloads from allow-listed domains
#
# Invoked automatically by devcontainer.json -> postStartCommand.
# Requires the NET_ADMIN capability (set via runArgs in devcontainer.json).
#
# NOTE: this is a guardrail, not a hard boundary. A user with sudo inside the
# codespace can flush these rules. For enforced control use Option 2 / 3.
###############################################################################
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[egress] starting dnsmasq domain allow-list..."
sudo cp "$DIR/dnsmasq.conf" /etc/dnsmasq.conf
sudo pkill dnsmasq 2>/dev/null || true
sudo dnsmasq --user=dnsmasq
# point the container resolver at local dnsmasq
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf >/dev/null

echo "[egress] applying iptables egress rules..."
sudo iptables -A OUTPUT -o lo -j ACCEPT
sudo iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Only the dnsmasq service may reach upstream DNS (port 53).
sudo iptables -A OUTPUT -p udp -m owner --uid-owner dnsmasq --dport 53 -j ACCEPT
sudo iptables -A OUTPUT -p tcp -m owner --uid-owner dnsmasq --dport 53 -j ACCEPT
# Applications may query the local dnsmasq only.
sudo iptables -A OUTPUT -p udp -d 127.0.0.1 --dport 53 -j ACCEPT
sudo iptables -A OUTPUT -p tcp -d 127.0.0.1 --dport 53 -j ACCEPT
# Block every other DNS path (direct external resolvers).
sudo iptables -A OUTPUT -p udp --dport 53 -j REJECT
sudo iptables -A OUTPUT -p tcp --dport 53 -j REJECT

# Block well-known DNS-over-HTTPS provider IPs on 443 (prevents DoH bypass).
for ip in 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4 9.9.9.9; do
  sudo iptables -A OUTPUT -p tcp -d "$ip" --dport 443 -j REJECT
done

# Allow HTTPS (port 443) for extension downloads from allow-listed domains.
# This includes:
#   - GitHub (github.com, api.github.com, github.dev)
#   - VS Code Marketplace and CDNs (marketplace.visualstudio.com, vscode-cdn.azureedge.net, etc)
#   - Microsoft CDNs (az764295.vo.msecnd.net, download.visualstudio.microsoft.com)
#   - Package registries (npmjs.org, pypi.org, etc)
# The DNS allow-list ensures only these domains resolve, so we can safely allow
# all HTTPS traffic to port 443.
echo "[egress] allowing HTTPS (port 443) for extension downloads..."
sudo iptables -A OUTPUT -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT

echo "[egress] lockdown applied. Manage allowed domains in dnsmasq.conf."
echo "[egress] Extensions can now download from allow-listed domains over HTTPS."
