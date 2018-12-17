#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

CONTAINERD_VERSION=${CONTAINERD_VERSION:-"1.2.1"}
RUNC_VERSION=${RUNC_VERSION:-"1.0.0-rc6"}

install-containerd() {
    apt-get update && apt-get install libseccomp2 -y
    wget https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}.linux-amd64.tar.gz
    wget https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64
    chmod +x runc.amd64
    mv runc.amd64 /usr/local/bin/runc
    tar -C /usr/local -xzf containerd-${CONTAINERD_VERSION}.linux-amd64.tar.gz

    mkdir -p /etc/containerd
    cat << EOF | sudo tee /etc/containerd/config.toml
subreaper = true
oom_score = -999
[plugins]
  [plugins.cri.containerd]
    snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runc"
      runtime_root = ""
EOF

    cat <<EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl restart containerd
}
