<div align="center">

# 🌐 Auto-Diagnosing Network Outage Detector
### *Automated Layered Fault-Isolation Engine*

[![Ubuntu](https://img.shields.io/badge/Ubuntu%20Server-22.04%20LTS-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Bash Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![VirtualBox](https://img.shields.io/badge/VirtualBox-Bridged%20NIC-183A61?style=for-the-badge&logo=virtualbox&logoColor=white)](https://www.virtualbox.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

<p align="center">
  <b>A proactive diagnostic engine that doesn't just ask <i>"is it down?"</i> — it isolates <i>why</i> and <i>where</i> the network boundary broke.</b>
</p>

---

</div>

## 📌 Problem & Engineering Motivation

Most monitoring agents only record binary uptime codes (`200 OK` vs. `Connection Timeout`). When an endpoint drops, traditional triage requires manual probing to distinguish between a dead local gateway, a broken DNS resolver, or an intermediate ISP routing failure.

This tool automates the **standard operational triage workflow** of a network engineer into a single automated execution pipeline:
## Motivation

Most basic monitoring tools tell you *that* something is down — they don't tell you *why*. When a device or service becomes unreachable, the actual cause could be at several different layers: the local network, DNS resolution, or somewhere further along the network path. NetDiag walks through these layers systematically, the same way a technician would when troubleshooting a real outage, and logs exactly where the failure occurs.

## Environment

- **OS:** Ubuntu Server 22.04 LTS, installed and configured from scratch on a self-managed virtual machine (VirtualBox)
- **Hardening:** SSH access configured, UFW firewall enabled with explicit SSH allow-rule (to avoid self-lockout)
- **Networking:** Configured with Bridged networking for direct LAN visibility, enabling the tool to interact with real network infrastructure (gateway, DNS, routing) rather than an isolated sandbox

## How it works

The script follows a layered diagnostic sequence, checking one layer at a time and stopping as soon as it identifies the root cause — the same logic used in real-world network troubleshooting (closely mirrors the OSI model's bottom-up debugging approach):

1. **Target reachability check** — pings the target (IP or domain) directly. If it responds, the script logs "UP" and exits immediately — no further diagnosis needed.
2. **Gateway/local network check** — if the target is unreachable, the script checks whether the local gateway (router) is reachable. If not, this confirms the problem is local (e.g., router down, cable disconnected, Wi-Fi issue) — no point checking DNS or further path if you can't even leave your own network.
3. **DNS resolution check** — if the gateway is reachable but the target still fails, the script checks whether the domain name resolves at all. This isolates DNS-specific failures (e.g., misconfigured DNS server, expired domain) from actual connectivity failures.
4. **Path trace (traceroute)** — if the target is still unreachable despite a working gateway and DNS, the script runs a traceroute to show exactly how far the connection gets before failing, pinpointing the approximate location of the break in the network path.

Every step is logged with a timestamp to `/var/log/diagnose.log`, so results are auditable and can be reviewed after the fact — not just observed live.

## Usage

```bash
sudo ./diagnose.sh <target>
```

Example:
```bash
sudo ./diagnose.sh google.com
```

View the log:
```bash
sudo cat /var/log/diagnose.log
```

## Sample log output

=== Diagnosing google.com at Thu Aug 28 14:32:10 UTC 2026 ===
RESULT: google.com is UP


For an unreachable target:

=== Diagnosing 10.99.99.99 at Thu Aug 28 14:35:02 UTC 2026 ===
ALERT: 10.99.99.99 is DOWN. Running diagnosis...
CHECK: Gateway 192.168.1.1 is reachable — local network OK
ROOT CAUSE: DNS resolution failure for 10.99.99.99


## Setup (if you want to run this yourself)

1. Provision a Linux server (physical, VM, or cloud instance)
2. Install required tools:
```bash
   sudo apt update && sudo apt install net-tools traceroute dnsutils -y
```
3. Clone this repo and make the script executable:
```bash
   git clone https://github.com/Shristi6392/Network-Diagnostics.git
   cd Network-Diagnostics
   chmod +x diagnose.sh
```
4. Run it:
```bash
   sudo ./diagnose.sh <target>
```

## A note on testing

During development, I discovered that VirtualBox's NAT networking mode intercepts and falsely responds to ICMP pings for non-routable addresses — meaning ping-based failure tests behaved inconsistently in that specific environment. Rather than accepting misleading results, I diagnosed the cause (NAT doesn't perform genuine routing the way Bridged mode or real hardware does) and validated the DNS-failure logic independently using `nslookup`, which correctly returned NXDOMAIN for a non-existent domain. This is a good example of understanding *why* a test environment behaves differently from production, rather than assuming code is broken when results look unexpected.

## Possible extensions

- Continuous monitoring via cron or a systemd timer, running checks on a schedule
- Alerting (email/Slack webhook) when a target goes down
- Parallel checks across multiple targets simultaneously
- Centralized logging for use across multiple servers, rather than a single-node script

## Author

Shristi Shukla — [GitHub](https://github.com/Shristi6392)
