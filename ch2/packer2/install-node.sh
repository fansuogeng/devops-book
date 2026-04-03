#!/usr/bin/env bash

set -e

wait_for_dnf() {
  while true; do
    local dnf_active=0
    local yum_active=0
    local lock_active=0

    pgrep -x dnf >/dev/null 2>&1 && dnf_active=1 || true
    pgrep -x yum >/dev/null 2>&1 && yum_active=1 || true
    sudo fuser /var/run/dnf.pid /var/lib/rpm/.rpm.lock >/dev/null 2>&1 && lock_active=1 || true

    if [[ "$dnf_active" -eq 0 && "$yum_active" -eq 0 && "$lock_active" -eq 0 ]]; then
      break
    fi

    echo "Waiting for background dnf/yum to finish..."
    sleep 5
  done
}

if command -v cloud-init >/dev/null 2>&1; then
  sudo cloud-init status --wait || true
fi

# Prevent scheduled metadata refresh from starting another dnf process mid-install.
sudo systemctl stop dnf-makecache.service dnf-makecache.timer >/dev/null 2>&1 || true
sudo systemctl mask dnf-makecache.service dnf-makecache.timer >/dev/null 2>&1 || true

wait_for_dnf

sudo tee /etc/yum.repos.d/nodesource-nodejs.repo > /dev/null <<EOF
[nodesource-nodejs]
name=NodeSource Node.js 23.x
baseurl=https://rpm.nodesource.com/pub_23.x/nodistro/nodejs/x86_64
gpgkey=https://rpm.nodesource.com/gpgkey/ns-operations-public.key
enabled=1
gpgcheck=1
EOF

sudo dnf clean all

for attempt in 1 2 3; do
  echo "Install attempt $attempt..."
  wait_for_dnf
  if sudo dnf install -y nodejs; then
    echo "Node.js installed successfully."
    exit 0
  fi
  echo "Attempt $attempt failed, cleaning cache and retrying..."
  sudo dnf clean all
  sleep 5
done

echo "All install attempts failed."
exit 1