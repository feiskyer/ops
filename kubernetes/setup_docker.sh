#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

CONTAINER_CIDR=${CONTAINER_CIDR:-"10.244.1.0/24"}

KUBERNTES_ROOT=$(dirname "${BASH_SOURCE}")
source ${KUBERNTES_ROOT}/lib/util.sh
source ${KUBERNTES_ROOT}/lib/docker.sh
source ${KUBERNTES_ROOT}/lib/cni.sh

install-docker-v1.13
