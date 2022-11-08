#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT=$(dirname "${BASH_SOURCE}")
source ${REPO_ROOT}/lib/util.sh
source ${REPO_ROOT}/lib/docker.sh

docker-install-latest
# lsb_dist=$(lsb-dist)
# case "$lsb_dist" in

#     ubuntu)
#         install-docker-v1.13-ubuntu
#     ;;

#     fedora|centos|redhat)
#         install-docker-v1.13-centos
#     ;;

#     *)
#         echo "$lsb_dist is not supported (not in centos|ubuntu)"
#     ;;

# esac
