# 🌐 Auto-Diagnosing Network Outage Detector

[![Linux](https://img.shields.io/badge/OS-Ubuntu%20Server%2022.04%20LTS-E95420?logo=ubuntu&logoColor=white)](#)
[![Bash](https://img.shields.io/badge/Language-Bash%20Shell-4EAA25?logo=gnu-bash&logoColor=white)](#)
[![Virtualization](https://img.shields.io/badge/Environment-VirtualBox%20(Bridged)-183A61?logo=virtualbox&logoColor=white)](#)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](#)

An automated fault-isolation and network troubleshooting tool written in Bash. Instead of merely recording status codes or reporting binary uptime/downtime, this tool systematically diagnoses and isolates the exact root cause of network outages using a layered, OSI-aligned diagnostic hierarchy.

---

## 📌 Problem & Motivation

Traditional monitoring scripts often flag a target as "DOWN" without providing actionable context. An outage could stem from a local interface issue, default gateway failure, DNS misconfiguration, or external transit degradation.

This project automates the manual triage workflow of an infrastructure technician, sequentially isolating:
1. **Target Reachability**: End-to-end ICMP ping health.
2. **Local Network Health**: Default gateway resolution and reachability.
3. **Name Resolution (DNS)**: Application/Domain Layer lookup validation.
4. **Transit Routing**: Hop-by-hop packet trace analysis via `traceroute` to identify the failure boundary.

---

## 🧱 Architectural Overview & Design Decisions

### Virtualization & Network Mode: Bridged vs. NAT
The diagnostic server runs inside a headless **Ubuntu Server 22.04 LTS** virtual machine deployed on Oracle VirtualBox.

* **Bridged Adapter Architecture**: The VM is attached directly to the host's physical network adapter. The local router assigns the VM an independent IP within the primary subnet (e.g., `192.168.1.x/24`), enabling genuine Layer 2/3 device probing and default gateway health checks.
* **Why Not NAT?**: Standard NAT places the VM behind host address translation (typically `10.0.2.x`), isolating it from the physical local area network and preventing true local gateway failure analysis.
* **Headless Deployment**: Provisioned without a Desktop GUI to minimize resource footprint (2GB RAM, 1 vCPU) and match enterprise data center server standards.

+--------------------------------------------------------------------------+
|                           Physical LAN Subnet                            |
|                                                                          |
|                     +--------------------------+                         |
|                     | Physical Router/Gateway  |                         |
|                     |      (192.168.1.1)       |                         |
|                     +------------+-------------+                         |
|                                  |                                       |
|                                  v                                       |
|                     +--------------------------+                         |
|                     |    Host Wi-Fi / NIC      |                         |
|                     +------------+-------------+                         |
+----------------------------------|---------------------------------------+
                                   | (Bridged Network Adapter)
+----------------------------------v---------------------------------------+
|  VirtualBox VM: netdiag-server                                           |
|  IP: 192.168.1.x/24  |  OS: Ubuntu Server 22.04 LTS                      |
|                                                                          |
|  +--------------------------------------------------------------------+  |
|  |                      diagnose.sh Execution Pipeline                |  |
|  |                                                                    |  |
|  |  [1. Ping Target]                                                  |  |
|  |         |                                                          |  |
|  |         +---> (Target DOWN)                                        |  |
|  |                     |                                              |  |
|  |                     v                                              |  |
|  |         [2. Gateway Health Check]                                  |  |
|  |                     |                                              |  |
|  |                     +---> (Gateway Reachable - Local OK)           |  |
|  |                                 |                                  |  |
|  |                                 v                                  |  |
|  |                     [3. DNS Resolution Query]                      |  |
|  |                                 |                                  |  |
|  |                                 +---> (DNS Resolved - Server OK)   |  |
|  |                                             |                      |  |
|  |                                             v                      |  |
|  |                                 [4. Traceroute Hop Analysis]       |  |
|  +--------------------------------------------------------------------+  |
+--------------------------------------------------------------------------+


---

## 🚀 Key Features

* **Target Availability Probing**: Fast ICMP polling with bounded timeouts.
* **Dynamic Gateway Auto-Detection**: Extracts default route via kernel routing tables (`ip route`).
* **DNS Resolution Verification**: Employs `nslookup` to separate name resolution problems from transport layer drops.
* **Route Path Tracing**: Limits traceroute to 15 hops to pinpoint intermediate upstream drop-offs.
* **Persistent System Logging**: Formats all diagnostic events and root causes into `/var/log/diagnose.log`.

---

## 🛠️ Installation & Setup

### Prerequisites
Install necessary diagnostic packages on your Debian/Ubuntu machine:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y openssh-server net-tools traceroute dnsutils
Script Deployment
Clone the repository:

Bash
git clone [https://github.com/Shristi6392/Network-Diagnostics.git](https://github.com/Shristi6392/Network-Diagnostics.git)
cd Network-Diagnostics
Make the diagnostic script executable:

Bash
chmod +x diagnose.sh
💻 Usage
Run the script against any domain name or IP address with sudo (required for log writes to /var/log/):

Bash
# Diagnosing a healthy target
sudo ./diagnose.sh google.com

# Diagnosing an unreachable or fake host
sudo ./diagnose.sh 10.99.99.99
📊 Sample Log Output (/var/log/diagnose.log)
Case 1: Healthy Target
Plaintext
=== Diagnosing google.com at Fri Aug 28 20:00:01 UTC 2026 ===
RESULT: google.com is UP
Case 2: Degraded Path / Unreachable Host
Plaintext
=== Diagnosing 10.99.99.99 at Fri Aug 28 20:02:15 UTC 2026 ===
ALERT: 10.99.99.99 is DOWN. Running diagnosis....
CHECK: Gateway 192.168.1.1 is reachable - local network OK
CHECK: DNS resolves 10.99.99.99 - DNS OK
Running traceroute to isolate failure point:
 1  192.168.1.1 (192.168.1.1)  1.124 ms  0.985 ms  0.874 ms
 2  10.20.0.1 (10.20.0.1)  5.431 ms  4.892 ms  5.102 ms
 3  * * *
 4  * * *
ROOT CAUSE: Target unreachable past network/DNS layer - see traceroute above
🧠 Diagnostic Logic (The "Why")
The script executes sequentially along the OSI stack:

Step	Scope	Tool	Diagnostic Rationale
1. Target Ping	End-to-End	ping	Confirms immediate reachability. If UP, exits early without overhead.
2. Gateway Ping	Layer 2 / Layer 3	ip route + ping	Tests local interface and router health. If gateway is down, flags local LAN outage.
3. DNS Resolution	Layer 7 / Application	nslookup	Distinguishes between global connectivity loss and simple name server resolution failure.
4. Hop Isolation	Layer 3 Network Path	traceroute	Maps the routing path to establish whether the fault is local, ISP-side, or destination-side.
🔮 Future Enhancements
Centralized Alerting: Integrate Webhook alerts for Slack and Discord notifications on outage triggers.

Cron Automation: Schedule daemonized checks across multiple edge hosts simultaneously.

Prometheus Metrics: Expose latency and failure codes as Prometheus metrics for Grafana dashboarding.

👤 Author
Shristi — GitHub Profile


---

Would you like to extend this script with an automated Cron job configuration or add multi-target health check arrays?
