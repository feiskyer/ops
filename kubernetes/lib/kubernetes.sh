#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

CLUSTER_CIDR=${CLUSTER_CIDR:-"10.244.0.0/16"}
CONTAINER_CIDR=${CONTAINER_CIDR:-"10.244.1.0/24"}
KUBERNTES_LIB_ROOT=$(dirname "${BASH_SOURCE}")

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
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    # kubernetes-cni will be installed automatically with kubelet
    yum install -y kubernetes-cni kubelet kubeadm kubectl
}

install-kubelet-ubuntu() {
    apt-get update && apt-get install -y apt-transport-https
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
    apt-get update
    # kubernetes-cni will be installed automatically with kubelet
    apt-get install -y kubernetes-cni kubelet kubeadm kubectl
}

setup-master() {
    kubeadm init --pod-network-cidr ${CLUSTER_CIDR} --config ${KUBERNTES_LIB_ROOT}/kubeadm.yaml
    # create default host-path storage class
    # kubectl create -f ${KUBERNTES_LIB_ROOT}/storage-class.yaml
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
    port="6443"
    if [[ $# == 3 ]]; then
        port="$3"
    fi

    # join master on worker nodes
    kubeadm join --token $token ${master_ip}:$port
}

