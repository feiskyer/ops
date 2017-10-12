#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

CLUSTER_CIDR=${CLUSTER_CIDR:-"10.244.0.0/16"}
CONTAINER_CIDR=${CONTAINER_CIDR:-"10.244.2.0/24"}
NETWORK_PLUGIN=${NETWORK_PLUGIN:-"calico"}
TOKEN=${TOKEN:-""}
MASTER_IP=${MASTER_IP:-""}

KUBERNTES_ROOT=$(dirname "${BASH_SOURCE}")
source ${KUBERNTES_ROOT}/lib/util.sh
source ${KUBERNTES_ROOT}/lib/docker.sh
source ${KUBERNTES_ROOT}/lib/kubernetes.sh
source ${KUBERNTES_ROOT}/lib/cni.sh
source ${KUBERNTES_ROOT}/lib/hyper.sh

install-network-plugin() {
    case "${NETWORK_PLUGIN}" in

        bridge)
            config-cni
            ;;

        calico)
            install-calico
            ;;

        flannel)
            install-flannel
            ;;

        *)
            echo "No network plugin is running, please add it manually"
            ;;
    esac
}

install-packages() {
    lsb_dist=$(lsb-dist)
    case "$lsb_dist" in

        ubuntu)
            install-docker-ubuntu
            install-kubelet-ubuntu
            install-network-plugin
        ;;

        fedora|centos|redhat)
            install-docker-centos
            install-kubelet-centos
            install-network-plugin
        ;;

        *)
            echo "$lsb_dist is not supported (not in centos|ubuntu)"
        ;;

    esac
}

usage() {
    echo "add_node     Install kubernetes and add join it to master."
    echo "add_node -s  Join node to master only (do not install packages)."
    echo "add_node -h  Show help message."
}

install=1
while getopts "sh" OPTION
do
    case $OPTION in
        s)
            echo "skipping install kubernetes packages"
            install=0
            ;;
        h)
            usage
            exit
            ;;
        ?)
            usage
            exit
            ;;
    esac
done

if [ "$TOKEN" = "" ] || [ "${MASTER_IP}" = "" ]; then
    echo "TOKEN and MASTER_IP must set"
    exit
fi

if [ $install = 1 ]; then
    install-packages
fi

setup-node $TOKEN ${MASTER_IP}
