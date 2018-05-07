#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

CONTAINERD_VERSION=${CONTAINERD_VERSION:-"1.1.0"}

install-containerd() {
    apt-get update && apt-get install libseccomp2 -y
    wget https://storage.googleapis.com/cri-containerd-release/cri-containerd-${CONTAINERD_VERSION}.linux-amd64.tar.gz
    tar -C / -xzf cri-containerd-${CONTAINERD_VERSION}.linux-amd64.tar.gz
    systemctl start containerd
}
