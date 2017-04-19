#!/bin/sh
#
# Add a new node to existing kubernetes cluster.
#
set -e

node_install() {
    # get token on master node
    token="$1"
    master_ip="$2"
    # join master on worker nodes
    kubeadm join --token $token ${master_ip}
}

node_install