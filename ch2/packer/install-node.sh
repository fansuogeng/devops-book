#!/usr/bin/env bash

set -e

#region agent log
echo "AGENT_LOG|H1|install-node.sh:start|script started"
ps -eo pid,comm,args | grep -E "dnf|yum|cloud-init" || true
#endregion

wait_for_dnf() {
  local start_ts
  start_ts=$(date +%s)
  #region agent log
  echo "AGENT_LOG|H1|install-node.sh:wait_for_dnf|checking for active package managers"
  #endregion
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
    #region agent log
    echo "AGENT_LOG|H5|install-node.sh:wait_state|dnf_active=$dnf_active yum_active=$yum_active lock_active=$lock_active elapsed=$(( $(date +%s) - start_ts ))s"
    pgrep -a dnf || true
    pgrep -a yum || true
    if [[ -f /var/run/dnf.pid ]]; then
      echo "AGENT_LOG|H5|install-node.sh:dnf_pid_file|$(cat /var/run/dnf.pid)"
    fi
    ps -eo pid,comm,args | grep -E "dnf|yum|cloud-init" || true
    #endregion
    sleep 5
  done

  #region agent log
  echo "AGENT_LOG|H5|install-node.sh:wait_done|elapsed=$(( $(date +%s) - start_ts ))s"
  #endregion
}

if command -v cloud-init >/dev/null 2>&1; then
  #region agent log
  echo "AGENT_LOG|H2|install-node.sh:cloud_init_wait|waiting on cloud-init status"
  #endregion
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
  #region agent log
  echo "AGENT_LOG|H3|install-node.sh:before_dnf_install|attempt=$attempt"
  #endregion
  if sudo dnf install -y nodejs; then
    echo "Node.js installed successfully."
    #region agent log
    echo "AGENT_LOG|H4|install-node.sh:dnf_install_success|attempt=$attempt"
    #endregion
    exit 0
  fi
  #region agent log
  echo "AGENT_LOG|H3|install-node.sh:dnf_install_failed|attempt=$attempt"
  #endregion
  echo "Attempt $attempt failed, cleaning cache and retrying..."
  sudo dnf clean all
  sleep 5
done

echo "All install attempts failed."
exit 1