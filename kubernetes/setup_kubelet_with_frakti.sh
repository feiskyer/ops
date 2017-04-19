#!/bin/bash
#
# Set kubelet with frakti runtime.
#
# Note: require kubelet managed by kubeadm.
#
set -e

kubelet_config() {
  sed -i '2 i\Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --container-runtime-endpoint=/var/run/frakti.sock --feature-gates=AllAlpha=true"' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
  systemctl daemon-reload
}

if [ -f /etc/systemd/system/kubelet.service.d/10-kubeadm.conf ]; then
  kubelet_config
else
  echo "Kubelet is not managed by kubeadm"
  exit 1
fi
