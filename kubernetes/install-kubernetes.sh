#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

CLUSTER_CIDR=${CLUSTER_CIDR:-"10.244.0.0/16"}
CONTAINER_CIDR=${CONTAINER_CIDR:-"10.244.1.0/24"}
NETWORK_PLUGIN=${NETWORK_PLUGIN:-"calico"}

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

lsb_dist=$(lsb-dist)
case "$lsb_dist" in

    ubuntu)
        install-docker-ubuntu
        install-kubelet-ubuntu
        setup-master
        install-network-plugin
    ;;

    fedora|centos|redhat)
        install-docker-centos
        install-kubelet-centos
        setup-master
        install-network-plugin
    ;;

    *)
        echo "$lsb_dist is not supported (not in centos|ubuntu)"
    ;;

esac

