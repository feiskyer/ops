#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

CONTAINER_RUNTIME=${CONTAINER_RUNTIME:-"docker"}
CLUSTER_CIDR=${CLUSTER_CIDR:-"10.244.0.0/16"}
CONTAINER_CIDR=${CONTAINER_CIDR:-"10.244.1.0/24"}
NETWORK_PLUGIN=${NETWORK_PLUGIN:-"flannel"}
USE_MIRROR=${USE_MIRROR:-""}

KUBERNTES_ROOT=$(dirname "${BASH_SOURCE}")
source ${KUBERNTES_ROOT}/lib/util.sh
source ${KUBERNTES_ROOT}/lib/kubernetes.sh
source ${KUBERNTES_ROOT}/lib/cni.sh

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

        weave)
            install-weave
            ;;

        azure)
            install-azure-vnet
            ;;

        *)
            echo "No network plugin is running, please add it manually"
            ;;
    esac
}

lsb_dist=$(lsb-dist)
case "$lsb_dist" in

    ubuntu)
        setup-container-runtime
        if [ "$USE_MIRROR" = "" ]; then
            install-kubelet-ubuntu
        else
            install-kubelet-ubuntu-mirror
        fi
        setup-master
        install-network-plugin
    ;;

    fedora|centos|redhat)
        setup-container-runtime
        if [ "$USE_MIRROR" = "" ]; then
            install-kubelet-centos
        else
            install-kubelet-centos-mirror
        fi
        setup-master
        install-network-plugin
    ;;

    *)
        echo "$lsb_dist is not supported (not in centos|ubuntu)"
    ;;

esac
