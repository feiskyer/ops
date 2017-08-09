#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

KUBERNTES_ROOT=$(dirname "${BASH_SOURCE}")
source ${KUBERNTES_ROOT}/lib/util.sh
source ${KUBERNTES_ROOT}/lib/hyper.sh

lsb_dist=$(lsb-dist)
case "$lsb_dist" in

    ubuntu)
        install-hyperd-ubuntu
    ;;

    fedora|centos|redhat)
        install-hyperd-centos
    ;;

    *)
        echo "$lsb_dist is not supported (not in centos|ubuntu)"
    ;;

esac

