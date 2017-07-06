#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

FRAKTI_VERSION=${FRAKTI_VERSION:-"v0.2"}
CLUSTER_CIDR=${CLUSTER_CIDR:-"10.244.0.0/16"}
CONTAINER_CIDR=${CONTAINER_CIDR:-"10.244.1.0/24"}

KUBERNTES_ROOT=$(dirname "${BASH_SOURCE}")
source ${KUBERNTES_ROOT}/lib/util.sh
source ${KUBERNTES_ROOT}/lib/docker.sh
source ${KUBERNTES_ROOT}/lib/kubernetes.sh
source ${KUBERNTES_ROOT}/lib/cni.sh
source ${KUBERNTES_ROOT}/lib/hyper.sh

lsb_dist=$(lsb-dist)
case "$lsb_dist" in

    ubuntu)
        install-hyperd-ubuntu
        install-docker-ubuntu
        install-frakti
        install-kubelet-ubuntu
        # frakti requires a newer CNI, install a latest released one.
        # TODO: remove this after it is in kubernetes repo
        install-cni-frakti
        config-cni-list
        config-kubelet-frakti
        setup-master
    ;;

    fedora|centos|redhat)
        install-hyperd-centos
        install-docker-centos
        install-frakti
        install-kubelet-centos
        # frakti requires a newer CNI, install a latest released one.
        # TODO: remove this after it is in kubernetes repo
        install-cni-frakti
        config-cni-list
        config-kubelet-frakti
        setup-master
    ;;

    *)
        echo "$lsb_dist is not supported (not in centos|ubuntu)"
    ;;

esac
