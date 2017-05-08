#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

FRAKTI_VERSION=${FRAKTI_VERSION:-"v0.2"}
CLUSTER_CIDR=${CLUSTER_CIDR:-"10.244.0.0/16"}
CONTAINER_CIDR=${CONTAINER_CIDR:-"10.244.1.0/24"}

install-kubelet-centos() {
    cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
    setenforce 0
    yum install -y kubernetes-cni kubelet kubeadm kubectl
}

install-kubelet-ubuntu() {
    apt-get update && apt-get install -y apt-transport-https
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
    apt-get update
    apt-get install -y kubernetes-cni kubelet kubeadm kubectl
}

setup-master() {
    kubeadm init kubeadm init --pod-network-cidr ${CLUSTER_CIDR} --kubernetes-version stable
    # Also enable schedule pods on the master for allinone.
    export KUBECONFIG=/etc/kubernetes/admin.conf
    kubectl taint nodes --all node-role.kubernetes.io/master-
}

setup-node() {
    if [[ $# < 2 ]]; then
        echo "Usage: setup-node token master_ip [port]"
        exit 1
    fi

    token="$1"
    master_ip="$2"
    if [[ $# == 3 ]]; then
        port="$3"
    fi
    if [ "$port" = "" ]; then
        port="6443"
    fi

    # join master on worker nodes
    kubeadm join --token $token ${master_ip}:$port
}

