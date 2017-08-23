#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

CLUSTER_CIDR=${CLUSTER_CIDR:-"10.244.0.0/16"}
CONTAINER_CIDR=${CONTAINER_CIDR:-"10.244.1.0/24"}
NETWORK_PLUGIN=${NETWORK_PLUGIN:-"flannel"}

KUBERNTES_ROOT=$(dirname "${BASH_SOURCE}")
source ${KUBERNTES_ROOT}/lib/util.sh
source ${KUBERNTES_ROOT}/lib/docker.sh
source ${KUBERNTES_ROOT}/lib/kubernetes.sh
source ${KUBERNTES_ROOT}/lib/cni.sh
source ${KUBERNTES_ROOT}/lib/hyper.sh

install-network-plugin() {
    case "${NETWORK_PLUGIN}" in

        bridge)
            # frakti requires a newer CNI, install a latest released one.
            # TODO: remove this after it is in kubernetes repo
            install-cni-frakti
            config-cni-list
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

fix-dns-resources() {
  kubectl -n kube-system patch deployment kube-dns -p '{"spec":{"template":{"spec":{"containers":[{"name":"kubedns","resources":{"limits":{"memory":"256Mi"}}},{"name":"dnsmasq","resources":{"limits":{"memory":"128Mi"}}},{"name":"sidecar","resources":{"limits":{"memory":"64Mi"}}}]}}}}'
}

lsb_dist=$(lsb-dist)
case "$lsb_dist" in

    ubuntu)
        install-hyperd-ubuntu
        install-docker-ubuntu
        install-frakti
        install-kubelet-ubuntu
        config-kubelet-frakti
        setup-master
        install-network-plugin
        fix-dns-resources
    ;;

    fedora|centos|redhat)
        install-hyperd-centos
        install-docker-centos
        install-frakti
        install-kubelet-centos
        config-kubelet-frakti
        setup-master
        install-network-plugin
        fix-dns-resources
    ;;

    *)
        echo "$lsb_dist is not supported (not in centos|ubuntu)"
    ;;

esac
