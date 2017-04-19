#!/bin/bash
#
# Set kubelet with docker runtime.
#
# Note: require kubelet managed by kubeadm.
#
set -e

kubelet_config() {
  sed -i '/frakti/d' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
  systemctl daemon-reload
}

if [ -f /etc/systemd/system/kubelet.service.d/10-kubeadm.conf ]; then
  kubelet_config
else
  echo "Kubelet is not managed by kubeadm"
  exit 1
fi
