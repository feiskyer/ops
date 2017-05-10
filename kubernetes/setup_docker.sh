#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

DOCKER_VERSION=${DOCKER_VERSION:-"v1.13"}

KUBERNTES_ROOT=$(dirname "${BASH_SOURCE}")
source ${KUBERNTES_ROOT}/lib/util.sh
source ${KUBERNTES_ROOT}/lib/docker.sh
source ${KUBERNTES_ROOT}/lib/cni.sh

docker-install-latest() {
    curl -fsSL https://get.docker.com/ | sh
    systemctl start docker
}

if [ "$DOCKER_VERSION" = "latest" ]; then
    docker-install-latest
else
    install-docker-v1.13
fi
