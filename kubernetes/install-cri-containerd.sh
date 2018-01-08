#!/bin/bash
# Install cri-containerd.
VERSION="1.0.0-beta.0"
sudo apt-get update && sudo apt-get install libseccomp2 -y
wget https://storage.googleapis.com/cri-containerd-release/cri-containerd-${VERSION}.linux-amd64.tar.gz

sudo tar -C / -xzf cri-containerd-${VERSION}.linux-amd64.tar.gz
sudo mkdir -p /opt/cni/bin/
sudo mkdir -p /etc/cni/net.d
sudo systemctl start containerd
sudo systemctl start cri-containerd

