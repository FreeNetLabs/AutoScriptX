#!/bin/bash

HOSTNAME=$(hostname)
OS=$(lsb_release -d | cut -f2-)
KERNEL=$(uname -r)
ARCH=$(uname -m)
CPU_MODEL=$(grep -m1 'model name' /proc/cpuinfo | cut -d ':' -f2- | sed 's/^ //')
CORES=$(nproc)
MEM_USED=$(free -h | awk '/Mem:/ {print $3 " / " $2}')
SWAP_USED=$(free -h | awk '/Swap:/ {print $3 " / " $2}')
DISK=$(df -h --output=source,size,used,avail,pcent,target)
IP_INT=$(hostname -I | awk '{print $1}')
IP_PUB=$(curl -s ifconfig.me || curl -s ipinfo.io/ip)
GATEWAY=$(ip route | grep default | awk '{print $3}')
DNS=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | paste -sd ', ')
UPTIME=$(uptime -p)
SERVICES=$(systemctl list-units --type=service --state=running --no-pager | awk '{print $1}' | tail -n +2)

gum format --theme=dracula <<EOF
# Basic Info
- **Hostname:** $HOSTNAME
- **OS:** $OS
- **Kernel:** $KERNEL
- **Architecture:** $ARCH

# CPU & Memory
- **CPU Model:** $CPU_MODEL
- **Cores:** $CORES
- **Memory Used:** $MEM_USED
- **Swap Used:** $SWAP_USED

# Disk Usage
\`\`\`
$DISK
\`\`\`

# Network Info
- **Internal IP:** $IP_INT
- **Public IP:** $IP_PUB
- **Gateway:** $GATEWAY
- **DNS Servers:** $DNS

# Uptime
- $UPTIME

# Running Services
\`\`\`
$SERVICES
\`\`\`
EOF

gum confirm "Return to menu?" && asx
