#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

DOCKER_VERSION=${DOCKER_VERSION:-"v1.13"}

KUBERNTES_ROOT=$(dirname "${BASH_SOURCE}")
source ${KUBERNTES_ROOT}/lib/util.sh
source ${KUBERNTES_ROOT}/lib/docker.sh

docker-install-latest() {
    curl -fsSL https://get.docker.com/ | sh
    systemctl start docker
}

if [ "$DOCKER_VERSION" = "latest" ]; then
    docker-install-latest
    exit 0
fi

lsb_dist=$(lsb-dist)
case "$lsb_dist" in

    ubuntu)
        install-docker-v1.13-ubuntu
    ;;

    fedora|centos|redhat)
        install-docker-v1.13-centos
    ;;

    *)
        echo "$lsb_dist is not supported (not in centos|ubuntu)"
    ;;

esac
