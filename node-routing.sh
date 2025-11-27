#!/usr/bin/env bash
set -euo pipefail

# Simple node-to-node routing helper
# Usage: node-routing.sh <1|2|3|4>

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <1|2>" >&2
  exit 1
fi

if [[ "$1" == "1" ]]; then
  ip route add 10.244.1.0/24 via 172.19.0.3 dev eth0
  ip route add 10.244.2.0/24 via 172.19.0.4 dev eth0
  ip route add 10.244.3.0/24 via 172.19.0.5 dev eth0
elif [[ "$1" == "2" ]]; then
  ip route add 10.244.0.0/24 via 172.19.0.2 dev eth0
  ip route add 10.244.2.0/24 via 172.19.0.4 dev eth0
  ip route add 10.244.3.0/24 via 172.19.0.5 dev eth0
elif [[ "$1" == "3" ]]; then
  ip route add 10.244.0.0/24 via 172.19.0.2 dev eth0
  ip route add 10.244.1.0/24 via 172.19.0.3 dev eth0
  ip route add 10.244.3.0/24 via 172.19.0.5 dev eth0
elif [[ "$1" == "4" ]]; then
  ip route add 10.244.0.0/24 via 172.19.0.2 dev eth0
  ip route add 10.244.1.0/24 via 172.19.0.3 dev eth0
  ip route add 10.244.2.0/24 via 172.19.0.4 dev eth0
else
  echo "Error: Argument must be 1, 2, 3, or 4" >&2
  exit 1
fi
