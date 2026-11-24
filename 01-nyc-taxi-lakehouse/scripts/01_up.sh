#!/usr/bin/env bash
# Start the Phase 1 cluster and wait until every service with a healthcheck reports healthy.
set -euo pipefail
cd "$(dirname "$0")/.."

docker compose up -d --wait --wait-timeout 300
echo
docker compose ps
echo
echo "Web UIs (Codespaces forwards these ports; open from the PORTS tab):"
echo "  NameNode        : 9870"
echo "  ResourceManager : 8088"
echo "  NodeManager     : 8042"
