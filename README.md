# 1 — In-container egress control for GitHub Codespaces

Drop the `.devcontainer/` folder at the root of your repository. On every
codespace start, egress is restricted to an allow-list.

## Files
| File | Purpose |
|------|---------|
| `.devcontainer/Dockerfile` | Installs `dnsmasq` + `iptables` |
| `.devcontainer/dnsmasq.conf` | Domain allow-list (default-deny) |
| `.devcontainer/egress-lockdown.sh` | Applies the DNS allow-list + iptables rules |
| `.devcontainer/devcontainer.json` | Adds `NET_ADMIN` and runs the lockdown on start |

## How it works
1. **dnsmasq** forwards only allow-listed domains; everything else resolves to
   `0.0.0.0` (blocked).
2. **iptables** forces all DNS through dnsmasq, blocks direct external
   resolvers, and blocks well-known DNS-over-HTTPS IPs so DNS can't tunnel
   over 443.

## Use it
1. Commit the `.devcontainer/` folder.
2. In VS Code: **Command Palette → Codespaces: Rebuild Container**.
3. Validate:
   ```bash
   nslookup github.com     # resolves
   nslookup example.com    # -> 0.0.0.0 (blocked)
   curl -sI https://example.com   # fails
   ```

## Manage the allow-list
Edit `dnsmasq.conf` — add a line `server=/yourdomain.com/1.1.1.1` per allowed
domain, then rebuild the container.

## Important
This is enforced **inside** the container. A user with `sudo` can flush the
rules — it is baseline hardening, not a hard security boundary. For
admin-enforced egress control use **Option 2** (Azure Firewall) or **Option 3**
(native VNet injection).
