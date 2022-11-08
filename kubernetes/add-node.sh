#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

CLUSTER_CIDR=${CLUSTER_CIDR:-"10.244.0.0/16"}
CONTAINER_CIDR=${CONTAINER_CIDR:-"10.244.2.0/24"}
NETWORK_PLUGIN=${NETWORK_PLUGIN:-"calico"}
TOKEN=${TOKEN:-""}
MASTER_IP=${MASTER_IP:-""}
USE_MIRROR=${USE_MIRROR:-""}

REPO_ROOT=$(dirname "${BASH_SOURCE}")
source ${REPO_ROOT}/lib/util.sh
source ${REPO_ROOT}/lib/kubernetes.sh
source ${REPO_ROOT}/lib/cni.sh

install-network-plugin() {
    case "${NETWORK_PLUGIN}" in

        bridge)
            config-cni
            ;;

        calico)
            echo "do nothing for calico."
            ;;

        flannel)
            echo "do nothing for flannel."
            ;;

        weave)
            echo "do nothing for weave."
            ;;

        azure)
            install-azure-vnet
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
            setup-container-runtime
            if [ "$USE_MIRROR" = "" ]; then
                install-kubelet-ubuntu
            else
                install-kubelet-ubuntu-mirror
            fi
            install-network-plugin
        ;;

        fedora|centos|redhat)
            setup-container-runtime
            if [ "$USE_MIRROR" = "" ]; then
                install-kubelet-centos
            else
                install-kubelet-centos-mirror
            fi
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
